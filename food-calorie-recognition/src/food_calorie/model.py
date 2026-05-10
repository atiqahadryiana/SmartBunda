"""Transfer-learning model builder for food classification."""

from __future__ import annotations

import tensorflow as tf

from food_calorie.config import IMAGE_SIZE


BACKBONES = ("mobilenet_v2", "efficientnet_b0")


def build_augmentation() -> tf.keras.Sequential:
    """Apply only training-time image variation to reduce overfitting."""

    return tf.keras.Sequential(
        [
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomRotation(0.08),
            tf.keras.layers.RandomZoom(0.15),
            tf.keras.layers.RandomBrightness(0.15),
        ],
        name="data_augmentation",
    )


def _base_model(
    backbone: str,
    input_shape: tuple[int, int, int],
) -> tuple[tf.keras.Model, tf.keras.layers.Layer]:
    if backbone == "mobilenet_v2":
        preprocess = tf.keras.layers.Rescaling(
            scale=1.0 / 127.5,
            offset=-1.0,
            name="mobilenet_v2_preprocess",
        )
        base = tf.keras.applications.MobileNetV2(
            input_shape=input_shape,
            include_top=False,
            weights="imagenet",
        )
        return base, preprocess

    if backbone == "efficientnet_b0":
        # Keras EfficientNet includes its own normalization at the model input.
        preprocess = tf.keras.layers.Activation("linear", name="efficientnet_preprocess")
        base = tf.keras.applications.EfficientNetB0(
            input_shape=input_shape,
            include_top=False,
            weights="imagenet",
        )
        return base, preprocess

    supported = ", ".join(BACKBONES)
    raise ValueError(f"Unsupported backbone '{backbone}'. Choose from: {supported}.")


def build_food_model(
    *,
    num_classes: int,
    image_size: tuple[int, int] = IMAGE_SIZE,
    backbone: str = "mobilenet_v2",
    dropout: float = 0.35,
) -> tuple[tf.keras.Model, tf.keras.Model]:
    """Build a mobile-friendly CNN classifier using transfer learning."""

    if num_classes < 2:
        raise ValueError("num_classes must be at least 2.")

    input_shape = (*image_size, 3)
    base, preprocess = _base_model(backbone, input_shape)
    base.trainable = False

    inputs = tf.keras.Input(shape=input_shape, name="image")
    x = preprocess(inputs)
    x = base(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D(name="global_average_pooling")(x)
    x = tf.keras.layers.Dense(256, activation="relu", name="dense_256")(x)
    x = tf.keras.layers.Dropout(dropout, name="dropout")(x)
    outputs = tf.keras.layers.Dense(
        num_classes,
        activation="softmax",
        name="food_probabilities",
    )(x)

    model = tf.keras.Model(inputs=inputs, outputs=outputs, name="food_calorie_model")
    return model, base


def compile_model(model: tf.keras.Model, learning_rate: float) -> None:
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate),
        loss=tf.keras.losses.SparseCategoricalCrossentropy(),
        metrics=["accuracy"],
    )


def unfreeze_for_fine_tuning(base_model: tf.keras.Model, unfreeze_layers: int) -> None:
    """Fine-tune the final convolution blocks while keeping batch norm stable."""

    if unfreeze_layers <= 0:
        return
    base_model.trainable = True
    cutoff = max(len(base_model.layers) - unfreeze_layers, 0)
    for index, layer in enumerate(base_model.layers):
        layer.trainable = index >= cutoff
        if isinstance(layer, tf.keras.layers.BatchNormalization):
            layer.trainable = False
