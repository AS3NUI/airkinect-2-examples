package com.as3nui.nativeExtensions.air.kinect.examples.skeleton
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectConfig;
	import com.as3nui.nativeExtensions.air.kinect.constants.JointNames;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	public class JointRotationsDemo extends DemoBase
	{
		
		private var kinect:Kinect;
		
		private var rgbImage:Bitmap;
		private var rgbSkeletonContainer:Sprite;
		private var skeletonContainer:Sprite;
		
		override protected function startDemoImplementation():void
		{
			trace("[JointRotationsDemo] Start Demo");
			if(Kinect.isSupported())
			{
				
				rgbImage = new Bitmap();
				addChild(rgbImage);
				
				rgbSkeletonContainer = new Sprite();
				addChild(rgbSkeletonContainer);
				
				skeletonContainer = new Sprite();
				addChild(skeletonContainer);
				
				kinect = Kinect.getKinect();
				
				kinect.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
				
				var config:KinectConfig = new KinectConfig();
				config.skeletonEnabled = true;
				config.rgbEnabled = true;
				
				kinect.start(config);
				
				addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			}
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			rgbSkeletonContainer.graphics.clear();
			skeletonContainer.graphics.clear();
			
			var joint:SkeletonJoint;
			var rotationVector:Vector3D;
			var centerX:uint = explicitWidth * .5;
			var centerY:uint = explicitHeight * .5;
			var drawX:uint = centerX;
			var drawY:uint = centerY;
			
			for each(var user:User in kinect.usersWithSkeleton)
			{
				if(user.hasSkeleton)
				{
					for each(joint in user.skeletonJoints)
					{
						//rgb overlay
						rgbSkeletonContainer.graphics.beginFill(0xFF0000);
						rgbSkeletonContainer.graphics.drawCircle(joint.rgbPosition.x, joint.rgbPosition.y, 5);
						rgbSkeletonContainer.graphics.endFill();
					}
					
					//draw bones according to joint orientation (z rotation = flash rotation)
					skeletonContainer.graphics.lineStyle(3, 0xFF0000);
					
					//
					// LEFT ARMS
					//
					
					skeletonContainer.graphics.moveTo(centerX, centerY);
					drawX = centerX;
					drawY = centerY;
					
					joint = user.getJointByName(JointNames.LEFT_SHOULDER);
					drawX = drawX + Math.cos(joint.orientation.z) * 100;
					drawY = drawY + Math.sin(joint.orientation.z) * 100;
					
					skeletonContainer.graphics.lineTo(drawX, drawY);
					
					joint = user.getJointByName(JointNames.LEFT_ELBOW);
					drawX = drawX + Math.cos(joint.orientation.z) * 100;
					drawY = drawY + Math.sin(joint.orientation.z) * 100;
					
					skeletonContainer.graphics.lineTo(drawX, drawY);
					
					//
					// RIGHT ARMS
					//
					skeletonContainer.graphics.moveTo(centerX, centerY);
					drawX = centerX;
					drawY = centerY;
					
					joint = user.getJointByName(JointNames.RIGHT_SHOULDER);
					drawX = drawX + Math.cos(joint.orientation.z + Math.PI) * 100;
					drawY = drawY + Math.sin(joint.orientation.z + Math.PI) * 100;
					
					skeletonContainer.graphics.lineTo(drawX, drawY);
					
					joint = user.getJointByName(JointNames.RIGHT_ELBOW);
					drawX = drawX + Math.cos(joint.orientation.z + Math.PI) * 100;
					drawY = drawY + Math.sin(joint.orientation.z + Math.PI) * 100;
					
					skeletonContainer.graphics.lineTo(drawX, drawY);
				}
			}
		}
		
		protected function rgbImageUpdateHandler(event:CameraImageEvent):void
		{
			rgbImage.bitmapData = event.imageData;
		}
		
		override protected function stopDemoImplementation():void
		{
			trace("[JointRotationsDemo] Stop Demo");
			if(kinect != null)
			{
				removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				
				kinect.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				kinect.stop();
			}
		}
	}
}