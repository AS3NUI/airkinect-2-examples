package com.as3nui.nativeExtensions.air.kinect.examples.cameras
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectConfig;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.KinectEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	
	import flash.display.Bitmap;
	import flash.events.Event;
	
	public class RGBCameraDemo extends DemoBase
	{
		
		private var rgbBitmap:Bitmap;
		private var kinect:Kinect;
		
		override protected function startDemoImplementation():void
		{
			if(Kinect.isSupported())
			{
				kinect = Kinect.getKinect();
				
				rgbBitmap = new Bitmap();
				addChild(rgbBitmap);
				
				kinect.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
				kinect.addEventListener(KinectEvent.STARTED, kinectStartedHandler, false, 0, true);
				kinect.addEventListener(KinectEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				
				var config:KinectConfig = new KinectConfig();
				config.rgbEnabled = true;
				config.rgbWidth = 640;
				config.rgbHeight = 480;
				
				kinect.start(config);
			}
		}
		
		protected function kinectStartedHandler(event:KinectEvent):void
		{
			trace("[RGBCameraDemo] kinect started");
		}
		
		protected function kinectStoppedHandler(event:KinectEvent):void
		{
			trace("[RGBCameraDemo] kinect stopped");
		}
		
		override protected function stopDemoImplementation():void
		{
			if(kinect != null)
			{
				kinect.stop();
				kinect.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				kinect.removeEventListener(KinectEvent.STARTED, kinectStartedHandler);
				kinect.removeEventListener(KinectEvent.STOPPED, kinectStoppedHandler);
			}
		}
		
		protected function rgbImageUpdateHandler(event:CameraImageEvent):void
		{
			rgbBitmap.bitmapData = event.imageData;
			layout();
		}
		
		override protected function layout():void
		{
			rgbBitmap.x = (explicitWidth - rgbBitmap.width) * .5;
			rgbBitmap.y = (explicitHeight - rgbBitmap.height) * .5;
		}
	}
}