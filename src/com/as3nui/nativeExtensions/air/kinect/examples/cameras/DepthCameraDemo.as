package com.as3nui.nativeExtensions.air.kinect.examples.cameras
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;

	import flash.display.Bitmap;

	public class DepthCameraDemo extends DemoBase
	{
		private var depthBitmap:Bitmap;
		private var device:Kinect;
		
		override protected function startDemoImplementation():void
		{
			if(Kinect.isSupported())
			{
				device = Kinect.getDevice();
				
				depthBitmap = new Bitmap();
				addChild(depthBitmap);
				
				device.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler, false, 0, true);
				device.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
				device.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				
				var settings:KinectSettings = new KinectSettings();
				settings.depthEnabled = true;
				settings.depthResolution = CameraResolution.RESOLUTION_640_480;
				settings.depthShowUserColors = true;
				
				device.start(settings);
			}
		}
		
		protected function kinectStartedHandler(event:DeviceEvent):void
		{
			trace("[DepthCameraDemo] kinect started");
		}
		
		protected function kinectStoppedHandler(event:DeviceEvent):void
		{
			trace("[DepthCameraDemo] kinect stopped");
		}
		
		override protected function stopDemoImplementation():void
		{
			if(device != null)
			{
				device.stop();
				device.removeEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler);
				device.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				device.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
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