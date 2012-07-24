package com.as3nui.nativeExtensions.air.kinect.examples.skeleton
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceErrorEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceInfoEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.UserEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	public class SkeletonBonesDemo extends DemoBase
	{
		
		private var kinect:Kinect;
		private var rgb:Bitmap;
		private var depth:Bitmap;
		
		private var skeletonRenderers:Vector.<SkeletonRenderer>;
		private var skeletonContainer:Sprite;

		private var settings:KinectSettings;
		
		public function SkeletonBonesDemo()
		{
			super();
		}
		
		override protected function startDemoImplementation():void
		{
			settings = new KinectSettings();
			settings.rgbEnabled = true;
			settings.rgbResolution = CameraResolution.RESOLUTION_320_240;
			settings.rgbMirrored = true;
			settings.depthEnabled = true;
			settings.depthResolution = CameraResolution.RESOLUTION_320_240;
			settings.depthMirrored = true;
			settings.skeletonEnabled = true;
			settings.skeletonMirrored = true;
			
			rgb = new Bitmap();
			addChild(rgb);
			
			depth = new Bitmap();
			addChild(depth);
			
			skeletonRenderers = new Vector.<SkeletonRenderer>();
			skeletonContainer = new Sprite();
			addChild(skeletonContainer);
			
			if(Kinect.isSupported())
			{
				kinect = Kinect.getDevice();
				
				kinect.addEventListener(DeviceInfoEvent.INFO, deviceInfoHandler, false, 0, true);
				kinect.addEventListener(DeviceErrorEvent.ERROR, deviceErrorHandler, false, 0, true);
				
				kinect.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
				kinect.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				
				kinect.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbHandler, false, 0, true);
				kinect.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthHandler, false, 0, true);
				
				kinect.addEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, skeletonsAddedHandler, false, 0, true);
				kinect.addEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, skeletonsRemovedHandler, false, 0, true);
				
				kinect.start(settings);
			}
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		}
		
		protected function deviceInfoHandler(event:DeviceInfoEvent):void
		{
			trace("[SkeletonBonesDemo] INFO " + event.message);
		}
		
		protected function deviceErrorHandler(event:DeviceErrorEvent):void
		{
			trace("[SkeletonBonesDemo] ERROR " + event.message);
		}
		
		protected function kinectStartedHandler(event:DeviceEvent):void
		{
			trace("[SkeletonBonesDemo] kinect started");
		}
		
		protected function kinectStoppedHandler(event:DeviceEvent):void
		{
			trace("[SkeletonBonesDemo] kinect stopped");
		}
		
		protected function rgbHandler(event:CameraImageEvent):void
		{
			rgb.bitmapData = event.imageData;
		}
		
		protected function depthHandler(event:CameraImageEvent):void
		{
			depth.bitmapData = event.imageData;
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
		
		protected function enterFrameHandler(event:Event):void
		{
			for each(var skeletonRenderer:SkeletonRenderer in skeletonRenderers)
			{
				skeletonRenderer.render();
			}
		}
		
		override protected function layout():void
		{
			depth.x = explicitWidth - settings.depthResolution.x;
			
			if(root)
			{
				root.transform.perspectiveProjection.projectionCenter = new Point(explicitWidth * .5, explicitHeight * .5);
			}
			if(skeletonContainer)
			{
				skeletonContainer.x = explicitWidth * .5;
				skeletonContainer.y = explicitHeight * .75;
				skeletonContainer.rotationX = 20;
			}
			
		}
		
		override protected function stopDemoImplementation():void
		{
			if(kinect)
			{
				kinect.removeEventListener(DeviceInfoEvent.INFO, deviceInfoHandler, false);
				kinect.removeEventListener(DeviceErrorEvent.ERROR, deviceErrorHandler, false);
				
				kinect.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler, false);
				kinect.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false);
				
				kinect.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbHandler, false);
				kinect.removeEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthHandler, false);
				
				kinect.removeEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, skeletonsAddedHandler, false);
				kinect.removeEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, skeletonsRemovedHandler, false);
				
				trace("[SkeletonBonesDemo] stop kinect");
				kinect.stop();
			}
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler, false);
		}
	}
}
import com.as3nui.nativeExtensions.air.kinect.data.SkeletonBone;
import com.as3nui.nativeExtensions.air.kinect.data.User;

import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

internal class SkeletonRenderer extends Sprite
{
	
	public var user:User;
	
	private var rootView:BoneView;
	
	public function SkeletonRenderer(user:User)
	{
		this.user = user;
		
		rootView = createBoneView(SkeletonBone.SPINE, 0, 0);
		
		trace("left lower arm bone info:", user.getBoneByName(SkeletonBone.LEFT_LOWER_ARM).startJointName,
			user.getBoneByName(SkeletonBone.LEFT_LOWER_ARM).endJointName,
			user.getBoneByName(SkeletonBone.LEFT_LOWER_ARM).parentBoneName);
		
		var spineView:BoneView = createBoneView(SkeletonBone.SPINE, 100, 0xff0000, rootView);
		var neckView:BoneView = createBoneView(SkeletonBone.NECK, 40, 0xff0000, spineView);
		
		var leftUpperArmView:BoneView = createBoneView(SkeletonBone.LEFT_UPPER_ARM, 100, 0xff0000, spineView);
		var leftLowerArmView:BoneView = createBoneView(SkeletonBone.LEFT_LOWER_ARM, 100, 0xff0000, leftUpperArmView);
		
		var rightUpperArmView:BoneView = createBoneView(SkeletonBone.RIGHT_UPPER_ARM, 100, 0xff0000, spineView);
		var rightLowerArmView:BoneView = createBoneView(SkeletonBone.RIGHT_LOWER_ARM, 100, 0xff0000, rightUpperArmView);
		
		var leftUpperLegView:BoneView = createBoneView(SkeletonBone.LEFT_UPPER_LEG, 100, 0xff0000, rootView);
		var leftLowerLegView:BoneView = createBoneView(SkeletonBone.LEFT_LOWER_LEG, 100, 0xff0000, leftUpperLegView);
		
		var rightUpperLegView:BoneView = createBoneView(SkeletonBone.RIGHT_UPPER_LEG, 100, 0xff0000, rootView);
		var rightLowerLegView:BoneView = createBoneView(SkeletonBone.RIGHT_LOWER_LEG, 100, 0xff0000, rightUpperLegView);
	}
	
	private function createBoneView(boneName:String, length:uint, color:uint, parentBone:BoneView = null):BoneView
	{
		var boneView:BoneView = new BoneView(boneName, length, color);
		boneView.name = boneName;
		if(parentBone)
		{
			boneView.parentBoneView = parentBone;
			boneView.parentBoneView.childBoneViews.push(boneView);
		}
		addChild(boneView);
		return boneView;
	}
	
	private function transformBoneAndChildBones(boneView:BoneView):void
	{
		var bone:SkeletonBone = user.getBoneByName(boneView.boneName);
		if(bone)
		{
			var m:Matrix3D = bone.orientation.absoluteOrientationMatrix.clone();
			if(m.determinant == 0) 
				m.identity();
			applyTranslation(m, boneView);
			boneView.transform.matrix3D = m;
		}
		else
		{
			boneView.rotationX = 0;
		}
		for each(var childBoneView:BoneView in boneView.childBoneViews)
		{
			transformBoneAndChildBones(childBoneView);
		}
	}
	
	private function applyTranslation(m:Matrix3D, boneView:BoneView):void
	{
		if(boneView.parentBoneView != null && boneView.parentBoneView.transform.matrix3D != null)
		{
			var p:Vector3D = new Vector3D(0, boneView.parentBoneView.lenght, 0);
			p = boneView.parentBoneView.transform.matrix3D.transformVector(p);
			m.appendTranslation(p.x, p.y, p.z);
		}
	}
	
	public function render():void
	{
		this.z = user.torso.position.world.z - 1000;
		transformBoneAndChildBones(rootView);
	}
}

internal class BoneView extends Shape
{
	
	private var _length:uint;
	
	public function get lenght():uint
	{
		return _length;
	}
	
	private var _boneName:String;
	
	public function get boneName():String
	{
		return _boneName;
	}
	
	public var framework:String;
	
	public var parentBoneView:BoneView;
	public var childBoneViews:Vector.<BoneView>;
	
	public function BoneView(boneName:String, length:uint, color:uint)
	{
		_length = length;
		_boneName = boneName;
		
		graphics.beginFill(color);
		graphics.drawRect(-10, 0, 20, length);
		graphics.endFill();
		
		childBoneViews = new Vector.<BoneView>();
	}
}