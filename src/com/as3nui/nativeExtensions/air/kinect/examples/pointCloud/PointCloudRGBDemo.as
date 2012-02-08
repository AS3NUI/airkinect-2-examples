package com.as3nui.nativeExtensions.air.kinect.examples.pointCloud
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectConfig;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.events.PointCloudEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	
	public class PointCloudRGBDemo extends DemoBase
	{
		
		private var kinect:Kinect;
		private var renderer:PointCloudRenderer;
		
		override protected function startDemoImplementation():void
		{
			if(Kinect.isSupported())
			{
				kinect = Kinect.getKinect();
				
				kinect.addEventListener(PointCloudEvent.POINT_CLOUD_UPDATE, pointCloudUpdateHandler, false, 0, true);
				
				var config:KinectConfig = new KinectConfig();
				config.pointCloudEnabled = true;
				config.pointCloudResolution = CameraResolution.RESOLUTION_640_480;
				config.pointCloudDensity = 2;
				config.pointCloudIncludeRGB = true;
				
				renderer = new PointCloudRenderer(config);
				addChild(renderer);
				
				kinect.start(config);
			}
		}
		
		protected function pointCloudUpdateHandler(event:PointCloudEvent):void
		{
			renderer.updatePoints(event.pointCloudData);
		}
		
		override protected function stopDemoImplementation():void
		{
			if(kinect != null)
			{
				kinect.removeEventListener(PointCloudEvent.POINT_CLOUD_UPDATE, pointCloudUpdateHandler);
				kinect.stop();
			}
		}
		
		override protected function layout():void
		{
			if(renderer != null)
			{
				renderer.x = (explicitWidth - renderer.width) * .5;
				renderer.y = (explicitHeight - renderer.height) * .5;
			}
		}
	}
}