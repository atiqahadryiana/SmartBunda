from foods import foods
from icrawler.builtin import BingImageCrawler
import os,time
from PIL import Image
import imagehash
import cv2

SIZE=(224,224)

# -------- SCRAPE --------
for food in foods:

    print("Downloading:",food)

    crawler=BingImageCrawler(storage={'root_dir':f'dataset/{food}'})
    crawler.crawl(keyword=f"{food} malaysia food",max_num=500)

    time.sleep(2)


# -------- REMOVE DUPLICATES --------
for food in os.listdir("dataset"):

    path=f"dataset/{food}"
    hashes=set()

    for file in os.listdir(path):

        try:
            img=Image.open(f"{path}/{file}")
            h=imagehash.average_hash(img)

            if h in hashes:
                os.remove(f"{path}/{file}")
            else:
                hashes.add(h)

        except:
            pass


# -------- RESIZE FOR ML --------
for food in os.listdir("dataset"):

    path=f"dataset/{food}"

    for file in os.listdir(path):

        try:
            img=cv2.imread(f"{path}/{file}")
            img=cv2.resize(img,SIZE)

            cv2.imwrite(f"{path}/{file}",img)

        except:
            pass

print("Dataset ready for TensorFlow")