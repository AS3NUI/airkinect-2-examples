package com.as3nui.nativeExtensions.air.kinect.examples.pointCloud
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.data.PointCloudRegion;
	import com.as3nui.nativeExtensions.air.kinect.events.PointCloudEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;

	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class PointCloudRegionsDemo extends DemoBase
	{
		
		private var device:Kinect;
		private var renderer:PointCloudRenderer;
		
		private var numPointsField1:TextField;
		private var numPointsField2:TextField;
		
		private var region1:PointCloudRegion;
		private var region2:PointCloudRegion;
		
		override protected function startDemoImplementation():void
		{
			if(Kinect.isSupported())
			{
				device = Kinect.getDevice();
				
				device.addEventListener(PointCloudEvent.POINT_CLOUD_UPDATE, pointCloudUpdateHandler, false, 0, true);
				
				var settings:KinectSettings = new KinectSettings();
				settings.pointCloudEnabled = true;
				settings.pointCloudResolution = CameraResolution.RESOLUTION_640_480;
				settings.pointCloudDensity = 4;
				//settings.pointCloudIncludeRGB = true;
				device.start(settings);
				
				region1 = new PointCloudRegion(200, 240, 900, 100, 50, 20);
				region2 = new PointCloudRegion(400, 240, 900, 100, 50, 20);
				
				var pointCloudRegions:Vector.<PointCloudRegion> = Vector.<PointCloudRegion>([region1, region2]);
				
				device.setPointCloudRegions(pointCloudRegions);
				
				renderer = new PointCloudRenderer(settings);
				addChild(renderer);
				renderer.updateRegions(pointCloudRegions);
				
				numPointsField1 = new TextField();
				numPointsField1.defaultTextFormat = new TextFormat("Arial", 16);
				numPointsField1.autoSize = TextFieldAutoSize.LEFT;
				addChild(numPointsField1);
				
				numPointsField2 = new TextField();
				numPointsField2.defaultTextFormat = new TextFormat("Arial", 16);
				numPointsField2.autoSize = TextFieldAutoSize.LEFT;
				addChild(numPointsField2);
			}
		}
		
		protected function pointCloudUpdateHandler(event:PointCloudEvent):void
		{
			renderer.updatePoints(event.pointCloudData);
			numPointsField1.text = "points: " + region1.numPoints;
			numPointsField2.text = "points: " + region2.numPoints;
		}
		
		override protected function stopDemoImplementation():void
		{
			if(device != null)
			{
				device.removeEventListener(PointCloudEvent.POINT_CLOUD_UPDATE, pointCloudUpdateHandler);
				device.stop();
			}
		}
		
		override protected function layout():void
		{
			if(renderer != null)
			{
				renderer.x = (explicitWidth - renderer.width) * .5;
				renderer.y = (explicitHeight - renderer.height) * .5;
				
				numPointsField1.x = renderer.x - 100;
				numPointsField2.x = renderer.x + renderer.width + 10;
				numPointsField1.y = numPointsField2.y = renderer.y + 10;
			}
		}
	}
}