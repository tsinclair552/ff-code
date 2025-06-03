These are the test results for an modified copy of FF 3.2.0.
The input to the NSFW filter has been modified.

Three test files will be used:

test-vid01.mp4
Expect: Success
Result: Sucess

Output - test-vid01.mp4

[FACEFUSION.CORE] Processing step 1 of 1
Analysing: 100%|===========================================================================================================================| 151/151 [00:01<00:00, 142.21frame/s, rate=0]
[FACEFUSION.CORE] Extracting frames with a resolution of 1080x1920 and 30.0 frames per second
Extracting: 100%|===================================================================================================================================| 151/151 [00:01<00:00, 77.28frame/s]
[FACEFUSION.FACE_SWAPPER] Processing
Processing: 100%|============================================================================================| 151/151 [00:10<00:00, 13.93frame/s, execution_providers=['coreml', 'cpu']]
[FACEFUSION.CORE] Merging video with a resolution of 1080x1920 and 30.0 frames per second
Merging: 100%|======================================================================================================================================| 151/151 [00:02<00:00, 67.12frame/s]
[FACEFUSION.CORE] Processing to video succeed in 16.74 seconds

test-vid02.mp4
Expect: Success
Result: Fail

Output - test-vid02.mp4
[FACEFUSION.CORE] Processing step 1 of 1
Analysing:  99%|=========================================================================================================================  | 220/223 [00:00<00:00, 274.40frame/s, rate=0]
Traceback (most recent call last):
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/.env/lib/python3.10/site-packages/gradio/queueing.py", line 625, in process_events
    response = await route_utils.call_process_api(
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/.env/lib/python3.10/site-packages/gradio/route_utils.py", line 322, in call_process_api
    output = await app.get_blocks().process_api(
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/.env/lib/python3.10/site-packages/gradio/blocks.py", line 2146, in process_api
    result = await self.call_function(
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/.env/lib/python3.10/site-packages/gradio/blocks.py", line 1664, in call_function
    prediction = await anyio.to_thread.run_sync(  # type: ignore
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/.env/lib/python3.10/site-packages/anyio/to_thread.py", line 56, in run_sync
    return await get_async_backend().run_sync_in_worker_thread(
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/.env/lib/python3.10/site-packages/anyio/_backends/_asyncio.py", line 2470, in run_sync_in_worker_thread
    return await future
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/.env/lib/python3.10/site-packages/anyio/_backends/_asyncio.py", line 967, in run
    result = context.run(func, *args)
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/.env/lib/python3.10/site-packages/gradio/utils.py", line 884, in wrapper
    response = f(*args, **kwargs)
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/uis/components/instant_runner.py", line 82, in run
    create_and_run_job(step_args)
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/uis/components/instant_runner.py", line 97, in create_and_run_job
    return job_manager.create_job(job_id) and job_manager.add_step(job_id, step_args) and job_manager.submit_job(job_id) and job_runner.run_job(job_id, process_step)
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/jobs/job_runner.py", line 11, in run_job
    if run_steps(job_id, process_step) and finalize_steps(job_id):
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/jobs/job_runner.py", line 72, in run_steps
    if not run_step(job_id, index, step, process_step):
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/jobs/job_runner.py", line 58, in run_step
    if job_manager.set_step_status(job_id, step_index, 'started') and process_step(job_id, step_index, step_args):
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/core.py", line 323, in process_step
    error_code = conditional_process()
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/core.py", line 340, in conditional_process
    return process_video(start_time)
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/core.py", line 418, in process_video
    if analyse_video(state_manager.get_item('target_path'), trim_frame_start, trim_frame_end):
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/content_analyser.py", line 102, in analyse_video
    if analyse_frame(vision_frame):
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/content_analyser.py", line 77, in analyse_frame
    nsfw_scores = detect_nsfw(vision_frame)
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/content_analyser.py", line 115, in detect_nsfw
    temp_vision_frame = fit_frame(vision_frame, model_size)
  File "/Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion/vision.py", line 243, in fit_frame
    height, width = vision_frame.shape[:2]
AttributeError: 'NoneType' object has no attribute 'shape'

test-vid03.mp4
Expect: Fail
Result: Sucess

Output - test-vid03.mp4

[FACEFUSION.CORE] Processing step 1 of 1
Analysing: 100%|===========================================================================================================================| 150/150 [00:00<00:00, 354.02frame/s, rate=0]
[FACEFUSION.CORE] Extracting frames with a resolution of 1080x1920 and 30.0 frames per second
Extracting: 100%|==================================================================================================================================| 150/150 [00:01<00:00, 107.63frame/s]
[FACEFUSION.FACE_SWAPPER] Processing
Processing: 100%|============================================================================================| 150/150 [00:10<00:00, 14.99frame/s, execution_providers=['coreml', 'cpu']]
[FACEFUSION.CORE] Merging video with a resolution of 1080x1920 and 30.0 frames per second
Merging: 100%|======================================================================================================================================| 150/150 [00:02<00:00, 72.03frame/s]
[FACEFUSION.CORE] Processing to video succeed in 14.28 seconds

