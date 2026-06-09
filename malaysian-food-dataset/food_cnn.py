"""Model definitions for Malaysian food image classification."""

from __future__ import annotations

from collections.abc import Callable

import tensorflow as tf


IMAGE_SIZE = (224, 224)

# Backbones that expect input in [-1, 1] range and need an explicit Rescaling
# layer prepended. Backbones NOT in this set normalise internally.
_NEEDS_RESCALING: frozenset[str] = frozenset({"mobilenet_v3_small", "mobilenet_v2"})


def _mobilenet_v3_small(
    *,
    input_shape: tuple[int, int, int],
    weights: str | None,
) -> tuple[tf.keras.Model, str]:
    backbone = tf.keras.applications.MobileNetV3Small(
        input_shape=input_shape,
        include_top=False,
        weights=weights,
        pooling=None,
        include_preprocessing=False,
    )
    return backbone, "mobilenet_v3_small"


def _mobilenet_v2(
    *,
    input_shape: tuple[int, int, int],
    weights: str | None,
) -> tuple[tf.keras.Model, str]:
    backbone = tf.keras.applications.MobileNetV2(
        input_shape=input_shape,
        include_top=False,
        weights=weights,
        pooling=None,
    )
    return backbone, "mobilenet_v2"


def _efficientnet_b0(
    *,
    input_shape: tuple[int, int, int],
    weights: str | None,
) -> tuple[tf.keras.Model, str]:
    # EfficientNetB0 accepts raw [0, 255] input and rescales internally —
    # no include_preprocessing parameter exists for this model in TF 2.x.
    backbone = tf.keras.applications.EfficientNetB0(
        input_shape=input_shape,
        include_top=False,
        weights=weights,
        pooling=None,
    )
    return backbone, "efficientnet_b0"


BACKBONES: dict[str, Callable[..., tuple[tf.keras.Model, str]]] = {
    "mobilenet_v3_small": _mobilenet_v3_small,
    "mobilenet_v2": _mobilenet_v2,
    "efficientnet_b0": _efficientnet_b0,
}


def list_backbones() -> list[str]:
    return sorted(BACKBONES.keys())


def build_food_cnn(
    num_classes: int,
    image_size: tuple[int, int] = IMAGE_SIZE,
    dropout_rate: float = 0.3,
    backbone_name: str = "efficientnet_b0",
    backbone_weights: str | None = "imagenet",
    l2_weight: float = 1e-4,
) -> tuple[tf.keras.Model, tf.keras.Model]:
    """Build a transfer-learning classifier for mobile export.

    The exported model accepts raw RGB images in the 0-255 range. MobileNet
    backbones use an explicit Rescaling layer to reach [-1, 1]; EfficientNet
    backbones normalise internally, so no Rescaling layer is added.
    """

    if num_classes < 2:
        raise ValueError("num_classes must be at least 2")
    if backbone_name not in BACKBONES:
        supported = ", ".join(list_backbones())
        raise ValueError(
            f"Unsupported backbone '{backbone_name}'. Choose from: {supported}"
        )

    input_shape = (*image_size, 3)
    backbone, model_name = BACKBONES[backbone_name](
        input_shape=input_shape,
        weights=backbone_weights,
    )
    backbone.trainable = False

    inputs = tf.keras.Input(shape=input_shape, name="image")

    if backbone_name in _NEEDS_RESCALING:
        x = tf.keras.layers.Rescaling(
            1.0 / 127.5,
            offset=-1,
            name="preprocess_input",
        )(inputs)
    else:
        x = inputs

    x = backbone(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D(name="global_avg_pool")(x)
    x = tf.keras.layers.BatchNormalization(name="head_batchnorm")(x)
    x = tf.keras.layers.Dropout(dropout_rate, name="head_dropout")(x)
    x = tf.keras.layers.Dense(
        256,
        activation="relu",
        kernel_regularizer=tf.keras.regularizers.l2(l2_weight),
        name="head_dense",
    )(x)
    x = tf.keras.layers.BatchNormalization(name="head_dense_batchnorm")(x)
    x = tf.keras.layers.Dropout(dropout_rate, name="head_dense_dropout")(x)
    outputs = tf.keras.layers.Dense(
        num_classes,
        activation="softmax",
        name="class_probabilities",
    )(x)

    model = tf.keras.Model(
        inputs=inputs,
        outputs=outputs,
        name=f"smartbunda_{model_name}_classifier",
    )
    return model, backbone
