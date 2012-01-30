package com.as3nui.nativeExtensions.air.kinect.examples.cameras
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectConfig;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.KinectEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	
	import flash.display.Bitmap;
	import flash.events.Event;
	
	public class InfraredCameraDemo extends DemoBase
	{
		private var infraredBitmap:Bitmap;
		private var kinect:Kinect;
		
		override protected function startDemoImplementation():void
		{
			if(Kinect.isSupported())
			{
				kinect = Kinect.getKinect();
				
				infraredBitmap = new Bitmap();
				addChild(infraredBitmap);
				
				kinect.addEventListener(CameraImageEvent.INFRARED_IMAGE_UPDATE, infraredImageUpdateHandler, false, 0, true);
				kinect.addEventListener(KinectEvent.STARTED, kinectStartedHandler, false, 0, true);
				kinect.addEventListener(KinectEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				
				var config:KinectConfig = new KinectConfig();
				config.infraredEnabled = true;
				config.infraredWidth = 640;
				config.infraredHeight = 480;
				
				kinect.start(config);
			}
		}
		
		protected function kinectStartedHandler(event:KinectEvent):void
		{
			trace("[InfraredCameraDemo] kinect started");
		}
		
		protected function kinectStoppedHandler(event:KinectEvent):void
		{
			trace("[InfraredCameraDemo] kinect stopped");
		}
		
		override protected function stopDemoImplementation():void
		{
			if(kinect != null)
			{
				kinect.stop();
				kinect.removeEventListener(CameraImageEvent.INFRARED_IMAGE_UPDATE, infraredImageUpdateHandler);
				kinect.removeEventListener(KinectEvent.STARTED, kinectStartedHandler);
				kinect.removeEventListener(KinectEvent.STOPPED, kinectStoppedHandler);
			}
		}
		
		protected function infraredImageUpdateHandler(event:CameraImageEvent):void
		{
			infraredBitmap.bitmapData = event.imageData;
			layout();
		}
		
		override protected function layout():void
		{
			infraredBitmap.x = (explicitWidth - infraredBitmap.width) * .5;
			infraredBitmap.y = (explicitHeight - infraredBitmap.height) * .5;
		}
	}
}