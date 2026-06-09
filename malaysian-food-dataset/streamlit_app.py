"""
SmartBunda AI Nutrition Tracker — Streamlit Prototype
======================================================
Tests the entire food-recognition pipeline before mobile deployment.

Install dependencies:
    pip install streamlit pillow numpy tensorflow plotly

Run:
    cd malaysian-food-dataset
    streamlit run streamlit_app.py
"""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Optional

import numpy as np
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st
from PIL import Image, ImageDraw, ImageFont

# ── Page config ───────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="SmartBunda AI Nutrition Tracker",
    page_icon="🍽️",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ── Custom CSS (SmartBunda pink theme) ────────────────────────────────────────
st.markdown("""
<style>
    /* Main background */
    .stApp { background: linear-gradient(135deg, #FFF5F8 0%, #FCE4EC 100%); }

    /* Metric cards */
    [data-testid="metric-container"] {
        background: #FDF9FA;
        border: 1px solid #F8BBD0;
        border-radius: 14px;
        padding: 14px;
        box-shadow: 0 4px 12px rgba(244, 143, 177, 0.15);
    }

    /* Primary button */
    .stButton>button {
        background: linear-gradient(135deg, #F48FB1 0%, #FF5C8A 100%);
        color: white;
        border: none;
        border-radius: 12px;
        font-weight: 700;
        padding: 10px 28px;
        transition: all 0.2s;
    }
    .stButton>button:hover {
        background: linear-gradient(135deg, #EC407A 0%, #FF4081 100%);
        box-shadow: 0 6px 20px rgba(236, 64, 122, 0.4);
        transform: translateY(-1px);
    }

    /* Headers */
    h1, h2, h3 { color: #333333; }
    h1 { color: #EC407A; }

    /* DataFrames */
    [data-testid="stDataFrame"] { border-radius: 12px; }

    /* Sidebar */
    [data-testid="stSidebar"] {
        background: #FFF5F8;
        border-right: 1px solid #F8BBD0;
    }
</style>
""", unsafe_allow_html=True)

# ── Constants ─────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
MODEL_PATH = SCRIPT_DIR / "artifacts" / "food_cnn.tflite"
LABELS_PATH = SCRIPT_DIR / "artifacts" / "labels.json"
INPUT_SIZE = (224, 224)

# ── Lazy imports (heavy) ──────────────────────────────────────────────────────
@st.cache_resource(show_spinner="Loading AI model…")
def load_model():
    """Load TFLite interpreter once and cache it."""
    try:
        import tensorflow as tf
        interpreter = tf.lite.Interpreter(str(MODEL_PATH))
        interpreter.allocate_tensors()
        return interpreter, "tflite"
    except Exception as exc:
        st.error(f"TFLite load failed: {exc}")
        return None, "none"


@st.cache_data
def load_labels() -> list[str]:
    if not LABELS_PATH.exists():
        return []
    raw = json.loads(LABELS_PATH.read_text())
    return [
        item["label"] if isinstance(item, dict) else item
        for item in raw
    ]


@st.cache_resource
def load_nutrition_db():
    from nutrition_db import lookup, FOODS
    return lookup, FOODS


# ── Inference ─────────────────────────────────────────────────────────────────

def preprocess(image: Image.Image) -> np.ndarray:
    """Resize and convert to float32 [0, 255] matching EfficientNetB0 input."""
    img = image.convert("RGB").resize(INPUT_SIZE, Image.LANCZOS)
    arr = np.array(img, dtype=np.float32)               # [224, 224, 3]
    return arr[np.newaxis, ...]                           # [1, 224, 224, 3]


def run_tflite(interpreter, img_array: np.ndarray) -> np.ndarray:
    inp = interpreter.get_input_details()
    out = interpreter.get_output_details()
    interpreter.set_tensor(inp[0]["index"], img_array)
    interpreter.invoke()
    return interpreter.get_tensor(out[0]["index"])[0]    # [num_classes]


def predict(image: Image.Image, top_k: int = 5) -> list[dict]:
    """Return top-k predictions with label, confidence, nutrition."""
    interpreter, mode = load_model()
    labels = load_labels()
    lookup, _ = load_nutrition_db()

    if interpreter is None or not labels:
        return []

    arr = preprocess(image)
    t0 = time.perf_counter()
    probs = run_tflite(interpreter, arr)
    latency_ms = (time.perf_counter() - t0) * 1000

    top_indices = np.argsort(probs)[::-1][:top_k]
    results = []
    for idx in top_indices:
        label = labels[idx] if idx < len(labels) else f"class_{idx}"
        conf = float(probs[idx])
        entry = lookup(label)
        results.append({
            "label": label,
            "display_name": entry.name if entry else label.replace("_", " ").title(),
            "confidence": conf,
            "category": entry.category if entry else "unknown",
            "entry": entry,
        })

    return results, latency_ms


# ── Drawing helpers ───────────────────────────────────────────────────────────

_COLORS = ["#EC407A", "#F48FB1", "#FF5C8A", "#BA68C8", "#22A6A3"]

def draw_single_food_box(
    image: Image.Image,
    label: str,
    confidence: float,
    color: str = "#EC407A",
) -> Image.Image:
    """Draw a single full-image bounding box for single-food classification."""
    img = image.copy().convert("RGB")
    draw = ImageDraw.Draw(img, "RGBA")
    w, h = img.size

    # Pink-tinted overlay at top
    margin = 8
    draw.rectangle(
        [(margin, margin), (w - margin, h - margin)],
        outline=color,
        width=4,
    )
    # Corner brackets
    br = 20  # bracket radius
    lw = 4
    for x, y, dx, dy in [(margin, margin, 1, 1), (w - margin, margin, -1, 1),
                          (margin, h - margin, 1, -1), (w - margin, h - margin, -1, -1)]:
        draw.line([(x, y + dy * br), (x, y), (x + dx * br, y)],
                  fill=color, width=lw)

    # Label pill at top-left
    text = f"{label}  {confidence:.0%}"
    pill_h = 32
    pill_w = len(text) * 9 + 20
    draw.rounded_rectangle(
        [(margin + 6, margin + 6), (margin + 6 + pill_w, margin + 6 + pill_h)],
        radius=8, fill=color,
    )
    try:
        font = ImageFont.truetype("arial.ttf", 16)
    except Exception:
        font = ImageFont.load_default()
    draw.text((margin + 16, margin + 10), text, fill="white", font=font)

    return img


# ── Nutrition charts ──────────────────────────────────────────────────────────

def macro_pie_chart(protein_g: float, fat_g: float, carbs_g: float) -> go.Figure:
    """Macronutrient breakdown donut chart."""
    labels = ["Protein", "Fat", "Carbohydrate"]
    kcal   = [protein_g * 4, fat_g * 9, carbs_g * 4]
    colors = ["#22A6A3", "#EC407A", "#BA68C8"]

    fig = go.Figure(go.Pie(
        labels=labels,
        values=kcal,
        hole=0.52,
        marker=dict(colors=colors, line=dict(color="white", width=2)),
        textinfo="label+percent",
        hovertemplate="%{label}: %{value:.0f} kcal (%{percent})<extra></extra>",
    ))
    fig.update_layout(
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        margin=dict(t=10, b=10, l=10, r=10),
        height=280,
        legend=dict(orientation="h", yanchor="bottom", y=-0.15),
        showlegend=True,
    )
    return fig


def confidence_bar_chart(predictions: list[dict]) -> go.Figure:
    """Horizontal bar chart of top-k confidence scores."""
    labels = [p["display_name"] for p in predictions]
    values = [p["confidence"] * 100 for p in predictions]
    colors = [_COLORS[i % len(_COLORS)] for i in range(len(predictions))]

    fig = go.Figure(go.Bar(
        y=labels[::-1],
        x=values[::-1],
        orientation="h",
        marker=dict(color=colors[::-1], line=dict(color="white", width=1)),
        text=[f"{v:.1f}%" for v in values[::-1]],
        textposition="inside",
        insidetextfont=dict(color="white", size=13),
        hovertemplate="%{y}: %{x:.1f}%<extra></extra>",
    ))
    fig.update_layout(
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        xaxis=dict(title="Confidence (%)", range=[0, 100],
                   gridcolor="#F8BBD0", showgrid=True),
        yaxis=dict(showgrid=False),
        margin=dict(t=10, b=30, l=10, r=10),
        height=max(200, 48 * len(predictions)),
    )
    return fig


def weekly_calorie_bar(history: list[dict]) -> go.Figure:
    days  = [h["date"] for h in history]
    kcals = [h["energy_kcal"] for h in history]
    fig = go.Figure(go.Bar(
        x=days, y=kcals,
        marker_color="#F48FB1",
        text=[f"{k:.0f}" for k in kcals],
        textposition="outside",
    ))
    fig.add_hline(y=2000, line_dash="dash", line_color="#EC407A",
                  annotation_text="Daily goal 2000 kcal")
    fig.update_layout(
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        xaxis=dict(showgrid=False),
        yaxis=dict(title="kcal", gridcolor="#F8BBD0"),
        margin=dict(t=30, b=10, l=10, r=10),
        height=260,
    )
    return fig


# ── Sidebar ───────────────────────────────────────────────────────────────────

def render_sidebar():
    st.sidebar.markdown("""
<div style='text-align:center; padding: 16px 0 8px;'>
    <div style='
        background: linear-gradient(135deg, #F48FB1, #FF5C8A);
        width: 56px; height: 56px; border-radius: 16px;
        display: inline-flex; align-items: center; justify-content: center;
        box-shadow: 0 6px 18px rgba(236,64,122,0.35);
        font-size: 26px;'>❤️</div>
    <h2 style='color:#EC407A; margin: 8px 0 2px; font-size:20px;'>SmartBunda</h2>
    <p style='color:#757575; font-size:13px; margin:0;'>AI Nutrition Tracker</p>
</div>
""", unsafe_allow_html=True)
    st.sidebar.divider()

    st.sidebar.subheader("⚙️ Settings")
    top_k = st.sidebar.slider("Top-K predictions", 1, 10, 5)
    portion_g = st.sidebar.number_input(
        "Portion size (g)", min_value=10, max_value=1000, value=200, step=10)
    daily_cal_goal = st.sidebar.number_input(
        "Daily calorie goal (kcal)", min_value=1200, max_value=4000, value=2000, step=50)

    st.sidebar.divider()
    st.sidebar.subheader("ℹ️ Model Info")
    labels = load_labels()
    interpreter, mode = load_model()
    st.sidebar.metric("Food classes", len(labels))
    st.sidebar.metric("Input size", "224 × 224")
    st.sidebar.metric("Model format", "TFLite FP16")
    if MODEL_PATH.exists():
        size_kb = MODEL_PATH.stat().st_size // 1024
        st.sidebar.metric("Model size", f"{size_kb} KB")

    st.sidebar.divider()
    st.sidebar.caption("Data: Malaysian Food Composition Database (MyFCD)\n"
                       "Source: myfcd.moh.gov.my")
    return top_k, portion_g, daily_cal_goal


# ── Tabs ──────────────────────────────────────────────────────────────────────

def tab_analyze(top_k: int, portion_g: float, daily_cal_goal: float):
    st.markdown("## 📸 Food Image Analyzer")
    st.markdown(
        "Upload or capture a food image to detect the dish and retrieve "
        "nutritional information from MyFCD."
    )

    # Upload
    col_up, col_cam = st.columns([3, 1])
    with col_up:
        uploaded = st.file_uploader(
            "Drag and drop a food image",
            type=["jpg", "jpeg", "png", "webp"],
            label_visibility="collapsed",
        )
    with col_cam:
        camera = st.camera_input("📷 Camera")

    image_source = camera if camera else uploaded
    if image_source is None:
        st.info("👆 Upload a food photo or use your camera to get started.")
        _render_example_cards()
        return

    image = Image.open(image_source)

    # Predict
    with st.spinner("🤖 Analysing image…"):
        result_data, latency_ms = predict(image, top_k=top_k)

    if not result_data:
        st.error("Model not ready. Ensure `artifacts/food_cnn.tflite` and "
                 "`artifacts/labels.json` exist.")
        return

    top_pred = result_data[0]
    lookup, _ = load_nutrition_db()

    # Annotated image + top result
    col_img, col_result = st.columns([1, 1])

    with col_img:
        annotated = draw_single_food_box(
            image,
            top_pred["display_name"],
            top_pred["confidence"],
            _COLORS[0],
        )
        st.image(annotated, caption="AI Detection Result", use_container_width=True)
        st.caption(f"⚡ Inference: {latency_ms:.1f} ms")

    with col_result:
        entry = top_pred["entry"]
        conf  = top_pred["confidence"]
        name  = top_pred["display_name"]

        # Confidence badge
        badge_color = "#66BB6A" if conf >= 0.7 else "#FFA726" if conf >= 0.4 else "#EF5350"
        st.markdown(f"""
<div style='
    background: {badge_color}22; border: 1.5px solid {badge_color};
    border-radius: 12px; padding: 14px 18px; margin-bottom: 12px;'>
    <div style='font-size:22px; font-weight:800; color:#333;'>{name}</div>
    <div style='font-size:14px; color:{badge_color}; font-weight:700; margin-top:4px;'>
        Confidence: {conf:.1%}
    </div>
    {'<div style="font-size:12px; color:#757575; margin-top:2px;">⚠️ Low confidence — verify manually</div>' if conf < 0.5 else ''}
</div>
""", unsafe_allow_html=True)

        if entry:
            nf = entry.per_grams(portion_g)
            c1, c2 = st.columns(2)
            c1.metric("🔥 Calories", f"{nf.energy_kcal:.0f} kcal")
            c2.metric("📏 Portion", f"{portion_g:.0f} g")
            c1.metric("🥩 Protein", f"{nf.protein_g:.1f} g")
            c2.metric("🧈 Fat", f"{nf.fat_g:.1f} g")
            c1.metric("🌾 Carbs", f"{nf.carbs_g:.1f} g")
            c2.metric("🥦 Fibre", f"{nf.fibre_g:.1f} g")
            st.metric("🧂 Sodium", f"{nf.sodium_mg:.0f} mg")

            # Pregnancy tip
            if nf.sodium_mg > 600:
                st.warning("⚠️ High sodium — limit intake for blood pressure management during pregnancy.")
            if nf.energy_kcal > daily_cal_goal * 0.4:
                st.warning(f"⚠️ This meal is >{40}% of your daily calorie goal.")
            if nf.fibre_g >= 4:
                st.success("✅ Good source of dietary fibre — supports healthy digestion.")
        else:
            st.info("Nutritional data not available for this food in MyFCD.")

    st.divider()

    # All predictions + macro chart
    col_bar, col_pie = st.columns([1, 1])

    with col_bar:
        st.subheader("📊 Top Predictions")
        st.plotly_chart(
            confidence_bar_chart(result_data),
            use_container_width=True,
        )

    with col_pie:
        if top_pred["entry"]:
            nf = top_pred["entry"].per_grams(portion_g)
            st.subheader("🥗 Macronutrient Breakdown")
            st.plotly_chart(
                macro_pie_chart(nf.protein_g, nf.fat_g, nf.carbs_g),
                use_container_width=True,
            )

    # Full nutrition table
    if top_pred["entry"]:
        st.subheader("📋 Full Nutrition Facts (MyFCD)")
        nf = top_pred["entry"].per_grams(portion_g)
        import pandas as pd
        df = pd.DataFrame([{
            "Nutrient": k, "Per 100g": f"{v/portion_g*100:.1f}",
            f"Per portion ({portion_g:.0f}g)": f"{v:.1f}",
        } for k, v in nf.as_dict().items()])
        st.dataframe(df, use_container_width=True, hide_index=True)

    # Add to log button
    st.divider()
    if st.button("➕ Add to daily log", key="add_log"):
        if "log" not in st.session_state:
            st.session_state["log"] = []
        if top_pred["entry"]:
            nf = top_pred["entry"].per_grams(portion_g)
            import datetime
            st.session_state["log"].append({
                "time": datetime.datetime.now().strftime("%H:%M"),
                "food": top_pred["display_name"],
                "portion_g": portion_g,
                **nf.as_dict(),
            })
            st.success(f"✅ Added {top_pred['display_name']} ({portion_g:.0f}g) to today's log.")


def tab_daily_log(daily_cal_goal: float):
    st.markdown("## 📅 Daily Food Log")

    log = st.session_state.get("log", [])
    if not log:
        st.info("No items logged today. Use the Analyze tab to scan food and add it here.")
        return

    import pandas as pd
    df = pd.DataFrame(log)
    st.dataframe(df, use_container_width=True, hide_index=True)

    st.divider()
    total_kcal = sum(r.get("Energy (kcal)", 0) for r in log)
    total_prot  = sum(r.get("Protein (g)", 0) for r in log)
    total_fat   = sum(r.get("Fat (g)", 0) for r in log)
    total_carbs = sum(r.get("Carbohydrate (g)", 0) for r in log)

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("🔥 Total kcal", f"{total_kcal:.0f}", f"/ {daily_cal_goal:.0f} goal")
    c2.metric("🥩 Protein", f"{total_prot:.1f} g")
    c3.metric("🧈 Fat", f"{total_fat:.1f} g")
    c4.metric("🌾 Carbs", f"{total_carbs:.1f} g")

    # Progress bar
    pct = min(total_kcal / daily_cal_goal, 1.0)
    bar_color = "#66BB6A" if pct < 0.85 else "#FFA726" if pct < 1.0 else "#EF5350"
    st.markdown(f"""
<div style='margin: 8px 0 18px;'>
    <div style='display:flex; justify-content:space-between; margin-bottom:4px;'>
        <span style='font-weight:700;'>Daily progress</span>
        <span style='color:{bar_color}; font-weight:700;'>{pct:.0%}</span>
    </div>
    <div style='background:#F8BBD0; border-radius:999px; height:12px; overflow:hidden;'>
        <div style='background:{bar_color}; width:{pct*100:.0f}%; height:100%; border-radius:999px;'></div>
    </div>
</div>
""", unsafe_allow_html=True)

    col_pie, col_tips = st.columns([1, 1])
    with col_pie:
        st.subheader("Macro split")
        st.plotly_chart(macro_pie_chart(total_prot, total_fat, total_carbs),
                        use_container_width=True)
    with col_tips:
        st.subheader("💡 Health insights")
        remaining_kcal = daily_cal_goal - total_kcal
        if remaining_kcal > 0:
            st.info(f"You have **{remaining_kcal:.0f} kcal** remaining for the day.")
        else:
            st.warning("You have exceeded your daily calorie goal.")

        # Pregnancy-specific tips
        st.markdown("""
**Pregnancy nutrition tips:**
- 🥛 Aim for **1000 mg calcium** daily (milk, tofu, fish)
- 💊 Take **30–60 mg iron** supplement daily
- 🥬 Ensure **400 μg folate** from green vegetables
- 💧 Drink **2.0–2.5 L water** daily
- 🚫 Avoid raw seafood, high-mercury fish, excess caffeine
""")

    if st.button("🗑️ Clear log"):
        st.session_state["log"] = []
        st.rerun()


def tab_model_info():
    st.markdown("## 🤖 AI Pipeline — Architecture & Audit")

    st.markdown("""
### Root Cause: `failed preconditions` Error

| Layer | Finding | Status |
|---|---|---|
| TFLite export | Used `tf.lite.Optimize.DEFAULT` → INT8 dynamic-range quantisation | ❌ Was broken |
| Android XNNPACK | Rejects hybrid INT8-weight + FP32-activation graphs | ❌ Was broken |
| **Fix applied** | Switched to **float16 quantisation** — fully supported by XNNPACK | ✅ Fixed |
| Model accuracy | MobileNetV3Small, 17 epochs, 0% val accuracy — pure random guessing | ⚠️ Need retrain |
| Data scarcity | Only 41 avg images/class (min 5, max 59) — far below 100 minimum | ⚠️ Need more data |
""")

    st.divider()
    st.subheader("📊 Architecture Comparison")

    import pandas as pd
    df = pd.DataFrame([
        dict(Model="MobileNetV3Small", Params="5.4M", TFLite_MB="~2.2 MB (FP16)",
             TopK_Food="60–65%", Mobile_ms="~10ms", Multi_food="❌", Recommended="Current"),
        dict(Model="EfficientNetB0", Params="5.3M", TFLite_MB="~10 MB (FP16)",
             TopK_Food="70–76%", Mobile_ms="~15ms", Multi_food="❌", Recommended="✅ Next step"),
        dict(Model="EfficientNetV2-S", Params="21.5M", TFLite_MB="~42 MB",
             TopK_Food="78–82%", Mobile_ms="~35ms", Multi_food="❌", Recommended="High accuracy"),
        dict(Model="YOLOv8n (cls)", Params="3.2M", TFLite_MB="~6 MB",
             TopK_Food="72–76%", Mobile_ms="~12ms", Multi_food="❌", Recommended="Fast option"),
        dict(Model="YOLOv8n (det)", Params="3.2M", TFLite_MB="~6 MB",
             TopK_Food="65–70% mAP", Mobile_ms="~15ms", Multi_food="✅", Recommended="⭐ Best for multi-food"),
        dict(Model="YOLOv11n (det)", Params="2.6M", TFLite_MB="~5 MB",
             TopK_Food="68–73% mAP", Mobile_ms="~12ms", Multi_food="✅", Recommended="Latest YOLO"),
        dict(Model="ViT-B/16", Params="86M", TFLite_MB="~330 MB",
             TopK_Food="82–86%", Mobile_ms="~150ms", Multi_food="❌", Recommended="Server only"),
    ])
    st.dataframe(df, use_container_width=True, hide_index=True)

    st.divider()
    st.subheader("🗺️ Recommended Migration Path")
    st.markdown("""
```
Phase 1 — Now (weeks 1–2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Retrain EfficientNetB0 with:
  • ≥100 images/class (scrape more via dataset_builder.py)
  • --min-images-per-class 80  --epochs 80
  • Float16 TFLite export (already fixed)
Expected accuracy: 60–75% top-1 on 80 classes

Phase 2 — Single-food production (week 3–4)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Evaluate with evaluate_and_promote.py --min-accuracy 0.55
• Deploy to Flutter via assets/ml/
• Add MyFCD nutrition lookup in-app

Phase 3 — Multi-food detection (month 2+)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Annotate 500+ images with bounding boxes (use Roboflow)
• Train YOLOv8n detection model
• Export to TFLite int8 (XNNPACK-compatible)
• Replace single-food classifier with YOLO detector
Expected: detect 2–4 foods per image with bounding boxes
```
""")

    st.divider()
    st.subheader("📐 Proposed Multi-Food Architecture")
    st.markdown("""
```
[Camera / Gallery]
       ↓
  Image (224×224 RGB)
       ↓
  ┌─────────────────────────┐
  │  YOLOv8n Detection       │  → Bounding boxes + class labels
  │  (TFLite INT8, ~6MB)    │  → Confidence scores
  └─────────────────────────┘
       ↓ (for each detected region)
  ┌─────────────────────────┐
  │  EfficientNetB0 Fine    │  → Fine-grained sub-category
  │  Classification          │    e.g. "ayam goreng berempah"
  └─────────────────────────┘
       ↓
  ┌─────────────────────────┐
  │  MyFCD Nutrition Lookup │  → Energy, Protein, Fat, Carbs
  │  (local JSON database)  │    Fibre, Sodium per 100g
  └─────────────────────────┘
       ↓
  Portion × per-100g values  → Total nutrition per food
       ↓
  Aggregated nutrition summary for entire meal
```
""")


def tab_database():
    st.markdown("## 🗄️ Malaysian Food Composition Database (MyFCD)")
    st.caption("Source: https://myfcd.moh.gov.my/ | Values per 100g edible portion")

    lookup, FOODS = load_nutrition_db()

    # Category filter
    categories = sorted({e.category for e in FOODS.values()})
    selected_cat = st.selectbox(
        "Filter by category",
        ["All"] + [c.title() for c in categories],
    )

    import pandas as pd
    rows = []
    for entry in FOODS.values():
        if selected_cat != "All" and entry.category != selected_cat.lower():
            continue
        rows.append({
            "Food": entry.name,
            "Category": entry.category.title(),
            "Energy (kcal)": entry.energy_kcal,
            "Protein (g)": entry.protein_g,
            "Fat (g)": entry.fat_g,
            "Carbs (g)": entry.carbs_g,
            "Fibre (g)": entry.fibre_g,
            "Sodium (mg)": entry.sodium_mg,
            "Portion (g)": entry.default_portion_g,
        })
    df = pd.DataFrame(rows).sort_values("Food")
    st.dataframe(df, use_container_width=True, hide_index=True, height=500)
    st.caption(f"Showing {len(df)} of {len(FOODS)} entries")

    # Search test
    st.subheader("🔍 Test fuzzy food name matching")
    query = st.text_input("Enter food name", "nasi lemak")
    if query:
        result = lookup(query)
        if result:
            nf = result.per_portion()
            st.success(f"Matched: **{result.name}** (category: {result.category})")
            cols = st.columns(6)
            for col, (k, v) in zip(cols, nf.as_dict().items()):
                col.metric(k.split(" ")[0], f"{v:.1f}")
        else:
            st.warning("No match found. Try a different spelling.")


# ── Helper widgets ─────────────────────────────────────────────────────────────

def _render_example_cards():
    st.markdown("#### 💡 Try these Malaysian dishes")
    cols = st.columns(4)
    examples = [
        ("🍚", "Nasi Lemak", "389 kcal / 100g"),
        ("🍜", "Char Kuey Teow", "182 kcal / 100g"),
        ("🥩", "Rendang Daging", "268 kcal / 100g"),
        ("🍵", "Teh Tarik", "72 kcal / 100g"),
    ]
    for col, (emoji, name, cal) in zip(cols, examples):
        col.markdown(f"""
<div style='
    background: #FDF9FA; border: 1px solid #F8BBD0;
    border-radius: 14px; padding: 14px; text-align: center;'>
    <div style='font-size: 28px;'>{emoji}</div>
    <div style='font-weight:700; color:#333; margin-top:6px;'>{name}</div>
    <div style='color:#757575; font-size:13px;'>{cal}</div>
</div>
""", unsafe_allow_html=True)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    top_k, portion_g, daily_cal_goal = render_sidebar()

    # Brand header
    st.markdown("""
<div style='
    background: linear-gradient(135deg, #FFF5F8 0%, #FCE4EC 100%);
    border: 1px solid #F8BBD0; border-radius: 20px;
    padding: 18px 24px; margin-bottom: 18px;
    display: flex; align-items: center; gap: 14px;'>
    <div style='
        background: linear-gradient(135deg, #F48FB1, #FF5C8A);
        width: 48px; height: 48px; border-radius: 14px;
        display: flex; align-items: center; justify-content: center;
        font-size: 22px;'>❤️</div>
    <div>
        <div style='font-size:22px; font-weight:800; color:#EC407A;'>SmartBunda</div>
        <div style='color:#757575; font-size:14px;'>AI Nutrition Tracker — Prototype</div>
    </div>
</div>
""", unsafe_allow_html=True)

    tab1, tab2, tab3, tab4 = st.tabs([
        "📸 Analyze Food",
        "📅 Daily Log",
        "🤖 AI Pipeline",
        "🗄️ MyFCD Database",
    ])

    with tab1:
        tab_analyze(top_k, portion_g, daily_cal_goal)
    with tab2:
        tab_daily_log(daily_cal_goal)
    with tab3:
        tab_model_info()
    with tab4:
        tab_database()


if __name__ == "__main__":
    main()
