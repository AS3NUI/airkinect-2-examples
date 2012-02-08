package com.as3nui.nativeExtensions.air.kinect.examples.cameras
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectConfig;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.KinectEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	
	import flash.display.Bitmap;
	
	public class DepthCameraDemo extends DemoBase
	{
		private var depthBitmap:Bitmap;
		private var kinect:Kinect;
		
		override protected function startDemoImplementation():void
		{
			if(Kinect.isSupported())
			{
				kinect = Kinect.getKinect();
				
				depthBitmap = new Bitmap();
				addChild(depthBitmap);
				
				kinect.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler, false, 0, true);
				kinect.addEventListener(KinectEvent.STARTED, kinectStartedHandler, false, 0, true);
				kinect.addEventListener(KinectEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				
				var config:KinectConfig = new KinectConfig();
				config.depthEnabled = true;
				config.depthResolution = CameraResolution.RESOLUTION_640_480;
				config.depthShowUserColors = true;
				
				kinect.start(config);
			}
		}
		
		protected function kinectStartedHandler(event:KinectEvent):void
		{
			trace("[DepthCameraDemo] kinect started");
		}
		
		protected function kinectStoppedHandler(event:KinectEvent):void
		{
			trace("[DepthCameraDemo] kinect stopped");
		}
		
		override protected function stopDemoImplementation():void
		{
			if(kinect != null)
			{
				kinect.stop();
				kinect.removeEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler);
				kinect.removeEventListener(KinectEvent.STARTED, kinectStartedHandler);
				kinect.removeEventListener(KinectEvent.STOPPED, kinectStoppedHandler);
			}
		}
		
		protected function depthImageUpdateHandler(event:CameraImageEvent):void
		{
			depthBitmap.bitmapData = event.imageData;
			layout();
		}
		
		override protected function layout():void
		{
			depthBitmap.x = (explicitWidth - depthBitmap.width) * .5;
			depthBitmap.y = (explicitHeight - depthBitmap.height) * .5;
		}
	}
}