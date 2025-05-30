# HW Specs

Mac Studio M2 Max
64 GB RAM
Sequoia 15.4.1

# Disabling NSFW

By default FaceFusion 3.2.0 is not allowing NSFW content. The preview is blurred for example.
I installed FaceFusion 3.2.0 using Pinookio 3.8.0
I found several other fixes, but none of them seem to work with 3.2.0, as the related files you needed to fix, have been changed considerably.

I figured out a fix with minimal changes to the code in order to get NSFW content working.

To find the files in Pinokio, you have to go to your Pinokio directory (in my case E:\tools\pinokio2).
For non-Pinokio installs the files should be easily to find as well.
In preview.py (in my case located in E:\tools\pinokio2\api\facefusion-pinokio.git\facefusion\facefusion\uis\components) change line 243:
From:
return cv2.GaussianBlur(target_vision_frame, (99, 99), 0)
To:
return cv2.GaussianBlur(target_vision_frame, (0, 0), 0)

In content_analyzer.py (in my case located in E:\tools\pinokio2\api\facefusion-pinokio.git\facefusion\facefusion) change line 124:
From:
nsfw_scores = nsfw_scores_raw.ravel().tolist()
To:
#nsfw_scores = nsfw_scores_raw.ravel().tolist()

This doesn't change anything on the fundamental code. The preview images are still blurred, but the blurr simply isn't visible.
And in content_analyzer it still flags NSFW content, but whatever it finds is not saved, because the line is commented out. 

# Modify start up on Mac to automatically use CPU in addition to coreml

What is the difference in processing speed between just coreml and coreml + cpu?

Test:

With just coreml - image faceswap - .91 secs
                   video faceswap (5 sec clip) - 12.68 secs

With coreml + cpu - image faceswap - .84 secs
                   video faceswap (5 sec clip) - 14.73 secs

Difference in performance is not substantial, at least for small files. This may add up for large batches, however.

No action to take at this time.

# Running FaceFusion in batch mode at the command line

Command format from FaceFusion Discord:

python facefusion.py batch-run -s SOURCE.jpg -t TARGET\FOLDER\\/*.mp4 -o OUTPUT\FOLDER\\/{index}.mp4


The facefusion.py script can be found in /Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion

Test command:

python facefusion.py run --ui-layouts benchmark

Error:

[FACEFUSION.CORE] FFMpeg is not installed

Test of batch-run:

Create folder Test_Bed in Downloads (/Users/tsinclair/Downloads) 
Copy source image /Volumes/SkyNet/Multimedia/Pix2/__InBox/_AI_Faces/Bratz.png to Test_Bed 

Test_Bed path is /Users/tsinclair/Downloads/Test_Bed 

Test command is:

python facefusion.py batch-run -s /Users/tsinclair/Downloads/Test_Bed/Bratz.png -t /Users/tsinclair/Downloads/Test_Bed\/*.mp4 -o /Users/tsinclair/Downloads/\/{index}.mp4

Same error as before

Posted a help message on Pinokio discord.

Startup command when run with Pinokio:


The default interactive shell is now zsh.
To update your account to use zsh, please run `chsh -s /bin/zsh`.
For more details, please visit https://support.apple.com/kb/HT208050.
<<PINOKIO_SHELL>>eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda deactivate ; conda activate /Users/tsinclair/pinokio/api/facefusion-pinokio.git/.env ; python facefusion.py run
* Running on local URL:  http://127.0.0.1:7860
* To create a public link, set `share=True` in `launch()`.

Test for CLI:

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda deactivate ; conda activate /Users/tsinclair/pinokio/api/facefusion-pinokio.git/.env ; python /Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion.py run

Output:

Traceback (most recent call last):
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion.py", line 10, in <module>
    core.cli()
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/core.py", line 43, in cli
    route(args)
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/core.py", line 71, in route
    if not common_pre_check() or not processors_pre_check():
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/core.py", line 130, in processors_pre_check
    if not processor_module.pre_check():
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/processors/modules/face_swapper.py", line 379, in pre_check
    model_hash_set = get_model_options().get('hashes')
AttributeError: 'NoneType' object has no attribute 'get'
(/Users/tsinclair/pinokio/api/facefusion-pinokio.git/.env)

From Reddit:

python3 
facefusion.py
 batch-run -s ~/Movies/face/face.png -t ./\*.png -o ./facefusion_output/{index}.png --face-swapper-model inswapper_128 --face-swapper-pixel-boost 512x512 --face-enhancer-model gfpgan_1.4 --face-enhancer-blend 80 --execution-providers coreml cpu --execution-thread-count 8

Also from Reddit:

python facefusion.py batch-run -s "F:\path\source\*.png" -t "F:\path\target\*.jpg" -o "F:\path\batch\fused_{index}.jpg" --execution-providers cuda --face-selector-mode many --face-swapper-model inswapper_128_fp16  --face-swapper-pixel-boost 1024x1024 --face-enhancer-model gfpgan_1.4 --face-enhancer-blend 100 --face-enhancer-weight 0.6 --expression-restorer-model live_portrait --face-editor-model live_portrait --expression-restorer-factor 80 --face-editor-mouth-smile 0.4 --frame-enhancer-model nomos8k_sc_x4 --frame-enhancer-blend 100 --face-selector-mode reference --face-selector-gender female --output-image-quality 90



Posted a question on the SubReddit about whether I need the additional CLI options specifying the other processors (ex. face-enhancer-blend)


## Response from Discord:
I guess you just need to activate the facefusion environment before starting facefusion. Have you done that?

cd to the directory 

cd /Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion

The command now works.

Next create a shell script that cd's to the directory and runs the command.

Need to set output folder

