package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel
{
	import away3d.animators.data.SkeletonAnimation;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.skeleton.JointPose;
	import away3d.animators.skeleton.SkeletonJoint;
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.library.AssetLibrary;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.textures.BitmapTexture;
	
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectConfig;
	import com.as3nui.nativeExtensions.air.kinect.constants.JointNames;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.KinectEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.UserEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.derschmale.away3d.loading.RotatedMD5MeshParser;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;
	
	public class RiggedModelDemo extends DemoBase
	{
		
		[Embed(source="/../assets/characters/hellknight/hellknight.jpg")]
		private var BodyAlbedo : Class;
		
		[Embed(source="/../assets/characters/hellknight/hellknight_s.png")]
		private var BodySpec : Class;
		
		[Embed(source="/../assets/characters/hellknight/hellknight_local.png")]
		private var BodyNorms : Class;
		
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var mesh:Mesh;
		private var bodyMaterial:TextureMaterial;
		private var colorMaterial:ColorMaterial;
		
		private var _light:PointLight;
		private var _light2:PointLight;
		private var _light3:PointLight;
		
		private var animationController:RiggedModelAnimationController;
		
		private var kinect:Kinect;
		
		private var rgbBitmap:Bitmap;
		private var rgbSkeletonContainer:Sprite;
		
		override protected function startDemoImplementation():void
		{
			trace("[RiggedModelDemo] Start Demo");
			
			scene = new Scene3D();
			camera = new Camera3D();
			
			camera.z = -100;
			camera.y = 100;
			
			view = new View3D();
			view.antiAlias = 4;
			view.backgroundColor = 0xFFFFFF;
			view.scene = scene;
			view.camera = camera;
			addChild(view);
			
			AssetLibrary.enableParser(RotatedMD5MeshParser);
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, assetCompleteHandler, false, 0, true);
			AssetLibrary.load(new URLRequest("assets/characters/hellknight/hellknight.md5mesh"));
			//AssetLibrary.load(new URLRequest("assets/characters/character3D/der3.md5mesh"));
		}
		
		protected function assetCompleteHandler(event:AssetEvent):void
		{
			trace("assetCompleteHandler");
			if (!(event.asset is Mesh)) return;
			
			trace("create mesh");
			
			mesh = Mesh(event.asset);
			
			initLights();
			initMaterials();
			
			mesh.material = bodyMaterial;
			//mesh.material = colorMaterial;
			
			
			for each(var skeletonJoint:away3d.animators.skeleton.SkeletonJoint in (mesh.animationState.animation as SkeletonAnimation).skeleton.joints)
			{
				trace(skeletonJoint.name, skeletonJoint.parentIndex);
			}
			
			//der3 model
			/*
			var jointMapping:Vector.<Number> = Vector.<Number>([
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("_head"), 			// XN_SKEL_HEAD
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("head"),			// XN_SKEL_NECK
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("torseDown"),		// XN_SKEL_TORSO
				
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("upArmL"), 		// XN_SKEL_LEFT_SHOULDER
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("foreArmL"),		// XN_SKEL_LEFT_ELBOW
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("handL"),			// XN_SKEL_LEFT_HAND
				
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("upArmR"), 		// XN_SKEL_RIGHT_SHOULDER
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("foreArmR"),		// XN_SKEL_RIGHT_ELBOW
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("handR"), 			// XN_SKEL_RIGHT_HAND
				
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("thighL"),			// XN_SKEL_LEFT_HIP
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("legL"),			// XN_SKEL_LEFT_KNEE
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("footL"),			// XN_SKEL_LEFT_FOOT
				
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("thighR"),			// XN_SKEL_RIGHT_HIP
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("legR"),			// XN_SKEL_RIGHT_KNEE
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("footR")			// XN_SKEL_RIGHT_FOOT
			]);
			*/
			
			var jointMapping:Vector.<Number> = Vector.<Number>([
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("head"), 			// XN_SKEL_HEAD
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("neck"),			// XN_SKEL_NECK
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("origin"),			// XN_SKEL_TORSO
			
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("luparm"), 		// XN_SKEL_LEFT_SHOULDER
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("lloarm"),			// XN_SKEL_LEFT_ELBOW
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("lwrist"),			// XN_SKEL_LEFT_HAND
			
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("ruparm"), 		// XN_SKEL_RIGHT_SHOULDER
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("rloarm"),			// XN_SKEL_RIGHT_ELBOW
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("rwrist"), 		// XN_SKEL_RIGHT_HAND
			
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("lupleg"),			// XN_SKEL_LEFT_HIP
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("lloleg"),			// XN_SKEL_LEFT_KNEE
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("lfoot"),			// XN_SKEL_LEFT_FOOT
			
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("rupleg"),			// XN_SKEL_RIGHT_HIP
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("rloleg"),			// XN_SKEL_RIGHT_KNEE
			(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("rfoot")			// XN_SKEL_RIGHT_FOOT
			]);
			
			jointMapping.fixed = true;
			
			animationController = new RiggedModelAnimationController(jointMapping, SkeletonAnimationState(mesh.animationState));
			
			scene.addChild(mesh);
			
			if(Kinect.isSupported())
			{
				kinect = Kinect.getKinect();
				
				rgbBitmap = new Bitmap();
				addChild(rgbBitmap);
				
				rgbSkeletonContainer = new Sprite();
				addChild(rgbSkeletonContainer);
				
				kinect.addEventListener(KinectEvent.STARTED, kinectStartedHandler, false, 0, true);
				kinect.addEventListener(KinectEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				kinect.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
				kinect.addEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler, false, 0, true);
				kinect.addEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler, false, 0, true);
				
				var config:KinectConfig = new KinectConfig();
				config.rgbEnabled = true;
				config.skeletonEnabled = true;
				
				trace("[RiggedModelDemo] Start Kinect");
				kinect.start(config);
			}
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		}
		
		protected function rgbImageUpdateHandler(event:CameraImageEvent):void
		{
			rgbBitmap.bitmapData = event.imageData;
		}
		
		protected function kinectStartedHandler(event:KinectEvent):void
		{
			trace("[RiggedModelDemo] Kinect started");
		}
		
		protected function kinectStoppedHandler(event:KinectEvent):void
		{
			trace("[RiggedModelDemo] Kinect stopped");
		}
		
		protected function usersWithSkeletonAddedHandler(event:UserEvent):void
		{
			trace("[RiggedModelDemo] User With Skeleton Added", event.users);
			if(animationController.kinectSkeleton == null)
			{
				animationController.kinectSkeleton = event.users[0];
			}
		}
		
		protected function usersWithSkeletonRemovedHandler(event:UserEvent):void
		{
			trace("[RiggedModelDemo] User With Skeleton Removed", event.users);
			for each(var removedUser:User in event.users)
			{
				if(removedUser == animationController.kinectSkeleton)
				{
					animationController.kinectSkeleton = null;
					break;
				}
			}
			if(kinect.usersWithSkeleton.length > 0)
			{
				animationController.kinectSkeleton = kinect.usersWithSkeleton[0];
			}
		}
		
		private function initLights():void
		{
			_light = new PointLight(); // DirectionalLight();
			_light.x = -5000;
			_light.y = 1000;
			_light.z = 7000;
			_light.color = 0xff1111;
			_light2 = new PointLight(); // DirectionalLight();
			_light2.x = 5000;
			_light2.y = 1000;
			_light2.z = 7000;
			_light2.color = 0x1111ff;
			_light3 = new PointLight();
			_light3.x = 30;
			_light3.y = 200;
			_light3.z = -100;
			_light3.color = 0xffeedd;
		}
		
		private function initMaterials():void
		{
			var lightPicker:StaticLightPicker = new StaticLightPicker([ _light, _light2, _light3 ]);
			
			bodyMaterial = new TextureMaterial(new BitmapTexture(new BodyAlbedo().bitmapData));
			bodyMaterial.lightPicker = lightPicker;
			bodyMaterial.ambientColor = 0x101020;
			bodyMaterial.ambient = 1;
			bodyMaterial.specularMap = new BitmapTexture(new BodySpec().bitmapData);
			bodyMaterial.normalMap = new BitmapTexture(new BodyNorms().bitmapData);
			
			colorMaterial = new ColorMaterial(0xFF0000);
			colorMaterial.lightPicker = lightPicker;
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			view.render();
			rgbSkeletonContainer.graphics.clear();
			for each(var user:User in kinect.usersWithSkeleton)
			{
				drawRGBBone(user.getJointByName(JointNames.LEFT_HAND), user.getJointByName(JointNames.LEFT_ELBOW));
				drawRGBBone(user.getJointByName(JointNames.LEFT_ELBOW), user.getJointByName(JointNames.LEFT_SHOULDER));
				drawRGBBone(user.getJointByName(JointNames.LEFT_SHOULDER), user.getJointByName(JointNames.NECK));
				drawRGBBone(user.getJointByName(JointNames.LEFT_SHOULDER), user.getJointByName(JointNames.TORSO));
				
				drawRGBBone(user.getJointByName(JointNames.RIGHT_HAND), user.getJointByName(JointNames.RIGHT_ELBOW));
				drawRGBBone(user.getJointByName(JointNames.RIGHT_ELBOW), user.getJointByName(JointNames.RIGHT_SHOULDER));
				drawRGBBone(user.getJointByName(JointNames.RIGHT_SHOULDER), user.getJointByName(JointNames.NECK));
				drawRGBBone(user.getJointByName(JointNames.RIGHT_SHOULDER), user.getJointByName(JointNames.TORSO));
				
				drawRGBBone(user.getJointByName(JointNames.HEAD), user.getJointByName(JointNames.NECK));
				
				drawRGBBone(user.getJointByName(JointNames.TORSO), user.getJointByName(JointNames.LEFT_HIP));
				drawRGBBone(user.getJointByName(JointNames.LEFT_HIP), user.getJointByName(JointNames.LEFT_KNEE));
				drawRGBBone(user.getJointByName(JointNames.LEFT_KNEE), user.getJointByName(JointNames.LEFT_FOOT));
				
				drawRGBBone(user.getJointByName(JointNames.TORSO), user.getJointByName(JointNames.RIGHT_HIP));
				drawRGBBone(user.getJointByName(JointNames.RIGHT_HIP), user.getJointByName(JointNames.RIGHT_KNEE));
				drawRGBBone(user.getJointByName(JointNames.RIGHT_KNEE), user.getJointByName(JointNames.RIGHT_FOOT));
				
				for each(var joint:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint in user.skeletonJoints)
				{
					rgbSkeletonContainer.graphics.lineStyle(2, 0xFFFFFF);
					rgbSkeletonContainer.graphics.beginFill(0xFF0000);
					rgbSkeletonContainer.graphics.drawCircle(joint.rgbPosition.x, joint.rgbPosition.y, 2);
					rgbSkeletonContainer.graphics.endFill();
				}
			}
		}
		
		private function drawRGBBone(from:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint, to:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint):void
		{
			rgbSkeletonContainer.graphics.lineStyle(3, 0xFF0000);
			rgbSkeletonContainer.graphics.moveTo(from.rgbPosition.x, from.rgbPosition.y);
			rgbSkeletonContainer.graphics.lineTo(to.rgbPosition.x, to.rgbPosition.y);
			rgbSkeletonContainer.graphics.lineStyle(0);
		}
		
		override protected function stopDemoImplementation():void
		{
			trace("[RiggedModelDemo] Stop Demo");
			AssetLibrary.removeEventListener(AssetEvent.ASSET_COMPLETE, assetCompleteHandler);
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			if(kinect != null)
			{
				kinect.removeEventListener(KinectEvent.STARTED, kinectStartedHandler);
				kinect.removeEventListener(KinectEvent.STOPPED, kinectStoppedHandler);
				kinect.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				kinect.removeEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler);
				kinect.removeEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler);
				kinect.stop();
			}
			view.dispose();
		}
		
		override protected function layout():void
		{
			if(view != null)
			{
				view.width = explicitWidth;
				view.height = explicitHeight;
			}
		}
	}
}