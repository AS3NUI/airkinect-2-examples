package com.as3nui.nativeExtensions.air.kinect.examples.cameras
{
	import com.as3nui.nativeExtensions.air.kinect.Device;
	import com.as3nui.nativeExtensions.air.kinect.DeviceSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;

	import flash.display.Bitmap;

	public class RGBCameraDemo extends DemoBase
	{
		
		private var rgbBitmap:Bitmap;
		private var device:Device;
		
		override protected function startDemoImplementation():void
		{
			if(Device.isSupported())
			{
				device = Device.getDeviceByOS();
				
				rgbBitmap = new Bitmap();
				addChild(rgbBitmap);
				
				device.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
				device.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
				device.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				
				var settings:DeviceSettings = new DeviceSettings();
				settings.rgbEnabled = true;
				settings.rgbResolution = CameraResolution.RESOLUTION_640_480;
				
				device.start(settings);
			}
		}
		
		protected function kinectStartedHandler(event:DeviceEvent):void
		{
			trace("[RGBCameraDemo] device started");
		}
		
		protected function kinectStoppedHandler(event:DeviceEvent):void
		{
			trace("[RGBCameraDemo] device stopped");
		}
		
		override protected function stopDemoImplementation():void
		{
			if(device != null)
			{
				device.stop();
				device.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				device.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				device.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
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