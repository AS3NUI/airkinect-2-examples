package com.as3nui.nativeExtensions.air.kinect.examples.basic
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectConfig;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.KinectEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	public class BasicDemo extends DemoBase
	{
		public static const KinectMaxDepthInFlash:uint = 200;

		private var kinect:Kinect;
		private var rgbBitmap:Bitmap;
		private var depthBitmap:Bitmap;
		
		private var rgbSkeletonContainer:Sprite;
		private var depthSkeletonContainer:Sprite;
		private var skeletonContainer:Sprite;
		
		override protected function startDemoImplementation():void
		{
			trace("[BasicDemo] startDemoImplementation");
			if(Kinect.isSupported())
			{
				kinect = Kinect.getKinect();
				
				rgbBitmap = new Bitmap();
				addChild(rgbBitmap);
				
				depthBitmap = new Bitmap();
				addChild(depthBitmap);
				
				rgbSkeletonContainer = new Sprite();
				addChild(rgbSkeletonContainer);
				
				depthSkeletonContainer = new Sprite();
				addChild(depthSkeletonContainer);
				
				skeletonContainer = new Sprite();
				addChild(skeletonContainer);
				
				kinect.addEventListener(KinectEvent.STARTED, kinectStartedHandler, false, 0, true);
				kinect.addEventListener(KinectEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				kinect.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
				kinect.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler, false, 0, true);
				
				var config:KinectConfig = new KinectConfig();
				config.rgbEnabled = true;
				config.depthEnabled = true;
				config.depthShowUserColors = true;
				config.skeletonEnabled = true;
				
				kinect.start(config);
				
				addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			}
		}
		
		protected function kinectStartedHandler(event:KinectEvent):void
		{
			trace("[BasicDemo] kinect started");
		}
		
		protected function kinectStoppedHandler(event:KinectEvent):void
		{
			trace("[BasicDemo] kinect stopped");
		}
		
		override protected function stopDemoImplementation():void
		{
			if(kinect != null)
			{
				kinect.stop();
				kinect.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				kinect.removeEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler);
				kinect.removeEventListener(KinectEvent.STARTED, kinectStartedHandler);
				kinect.removeEventListener(KinectEvent.STOPPED, kinectStoppedHandler);
			}
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			rgbSkeletonContainer.graphics.clear();
			depthSkeletonContainer.graphics.clear();
			skeletonContainer.removeChildren();
			for each(var user:User in kinect.users)
			{
				if(user.hasSkeleton)
				{
					for each(var joint:SkeletonJoint in user.skeletonJoints)
					{
						if(joint.positionConfidence > .5)
						{
							rgbSkeletonContainer.graphics.beginFill(0xFF0000);
							rgbSkeletonContainer.graphics.drawCircle(joint.rgbPosition.x, joint.rgbPosition.y, 5);
							rgbSkeletonContainer.graphics.endFill();
							
							depthSkeletonContainer.graphics.beginFill(0xFF0000);
							depthSkeletonContainer.graphics.drawCircle(joint.depthPosition.x, joint.depthPosition.y, 5);
							depthSkeletonContainer.graphics.endFill();
							
							var color:uint = (joint.positionRelative.z / (KinectMaxDepthInFlash * 4)) * 255 << 16 | (1 - (joint.positionRelative.z / (KinectMaxDepthInFlash * 4))) * 255 << 8 | 0;
							
							var jointSprite:Sprite = createCircleForPosition(joint.positionRelative, color);
							skeletonContainer.addChild(jointSprite);
						}
					}
				}
				//user center position
				var userCenterSprite:Sprite = createCircleForPosition(user.positionRelative, 0xFF0000);
				skeletonContainer.addChild(userCenterSprite);
			}
		}
		
		private function createCircleForPosition(positionRelative:Vector3D, color:uint):Sprite
		{
			var xPos:Number = ((positionRelative.x + 1) * .5) * explicitWidth;
			var yPos:Number = ((positionRelative.y - 1) / -2) * explicitHeight;
			var zPos:Number = positionRelative.z * KinectMaxDepthInFlash;
			
			var circle:Sprite = new Sprite();
			circle.graphics.beginFill(color);
			circle.graphics.drawCircle(0, 0, 15);
			circle.graphics.endFill();
			circle.x = xPos;
			circle.y = yPos;
			circle.z = zPos;
			
			return circle;
		}
		
		protected function depthImageUpdateHandler(event:CameraImageEvent):void
		{
			depthBitmap.bitmapData = event.imageData;
			layout();
		}
		
		protected function rgbImageUpdateHandler(event:CameraImageEvent):void
		{
			rgbBitmap.bitmapData = event.imageData;
		}
		
		override protected function layout():void
		{
			if(depthBitmap != null)
			{
				depthBitmap.x = explicitWidth - depthBitmap.width;
				depthSkeletonContainer.x = depthBitmap.x;
			}
			if(root != null)
			{
				root.transform.perspectiveProjection.projectionCenter = new Point(explicitWidth * .5, explicitHeight * .5);
			}
		}
	}
}