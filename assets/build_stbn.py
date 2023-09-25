from pathlib import Path
from PIL import Image
import numpy as np

seq_name = 'stbn_vec3_2Dx1D_128x128x64_{}.png'
basedir = Path('./STBN').resolve()

imgs = []

for i in range(64):
    img = Image.open(basedir / seq_name.format(i))
    img = np.array(img)
    imgs.append(img)

imgs = np.stack(imgs, axis=2)

print(imgs.shape)

imgbytes = imgs.astype(np.float32).tobytes()

outdir = basedir.parent.parent / 'shaders/assets/'
outdir.mkdir(parents=True, exist_ok=True)

outf = open(outdir / 'stbn.bin', 'wb')
outf.write(imgbytes)
outf.close()
