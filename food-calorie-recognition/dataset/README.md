# Dataset Structure

Place images in one folder per food class. Folder names become class labels.
Use lowercase names with underscores for labels that have spaces.

```text
dataset/
  pizza/
    pizza_001.jpg
    pizza_002.jpg
  burger/
    burger_001.jpg
  salad/
    salad_001.jpg
  nasi_lemak/
    nasi_lemak_001.jpg
  fried_rice/
    fried_rice_001.jpg
  spaghetti/
    spaghetti_001.jpg
```

Recommended minimum: 100-300 images per class for a prototype, more for a
production model. Keep the lighting, angle, plating, and background varied.

The trainer creates deterministic training, validation, and testing splits from
these folders. Keep a separate external test folder as well if you need a final
unseen benchmark for reporting.
