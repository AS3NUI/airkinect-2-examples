package com.as3nui.nativeExtensions.air.kinect.examples.skeleton
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.UserEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class SkeletonDemo extends DemoBase
	{
		private var device:Kinect;
		private var skeletonRenderers:Vector.<SkeletonRenderer>;
		private var skeletonContainer:Sprite;
		
		override protected function startDemoImplementation():void
		{
			if(Kinect.isSupported())
			{
				device = Kinect.getDevice();
				
				var settings:KinectSettings = new KinectSettings();
				settings.skeletonEnabled = true;
				
				device.addEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, skeletonsAddedHandler, false, 0, true);
				device.addEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, skeletonsRemovedHandler, false, 0, true);
				
				skeletonRenderers = new Vector.<SkeletonRenderer>();
				skeletonContainer = new Sprite();
				addChild(skeletonContainer);
				
				addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
				device.start(settings);
			}
		}
		
		protected function skeletonsRemovedHandler(event:UserEvent):void
		{
			for each(var removedUser:User in event.users)
			{
				var index:int = -1;
				for(var i:int = 0; i < skeletonRenderers.length; i++)
				{
					if(skeletonRenderers[i].user == removedUser)
					{
						index = i;
						break;
					}
				}
				if(index > -1)
				{
					skeletonContainer.removeChild(skeletonRenderers[index]);
					skeletonRenderers.splice(index, 1);
				}
			}
		}
		
		protected function skeletonsAddedHandler(event:UserEvent):void
		{
			for each(var addedUser:User in event.users)
			{
				var skeletonRenderer:SkeletonRenderer = new SkeletonRenderer(addedUser);
				skeletonContainer.addChild(skeletonRenderer);
				skeletonRenderers.push(skeletonRenderer);
			}
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			for each(var skeletonRenderer:SkeletonRenderer in skeletonRenderers)
			{
				skeletonRenderer.render();
			}
		}
		
		override protected function stopDemoImplementation():void
		{
			if(device != null)
			{
				removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				device.removeEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, skeletonsAddedHandler);
				device.removeEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, skeletonsRemovedHandler);
				device.stop();
			}
		}
	}
}
import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
import com.as3nui.nativeExtensions.air.kinect.data.User;
import com.bit101.components.Label;

import flash.display.Sprite;

internal class SkeletonRenderer extends Sprite
{
	
	public var user:User;
	private var labels:Vector.<Label>;
	
	public function SkeletonRenderer(user:User)
	{
		this.user = user;
		labels = new Vector.<Label>();
	}
	
	public function render():void
	{
		graphics.clear();
		var numJoints:uint = user.skeletonJoints.length;
		//create labels
		while(labels.length < numJoints)
		{
			labels.push(new Label(this));
		}
		for(var i:int = 0; i < numJoints; i++)
		{
			var joint:SkeletonJoint = user.skeletonJoints[i];
			var label:Label = labels[i];
			//circle
			graphics.beginFill(0xFF0000);
			graphics.drawCircle(joint.depthRelativePosition.x * stage.stageWidth, joint.depthRelativePosition.y * stage.stageHeight, 10);
			graphics.endFill();
			//label
			label.text = joint.name;
			label.x = joint.depthRelativePosition.x * stage.stageWidth;
			label.y = joint.depthRelativePosition.y * stage.stageHeight;
		}
	}
}