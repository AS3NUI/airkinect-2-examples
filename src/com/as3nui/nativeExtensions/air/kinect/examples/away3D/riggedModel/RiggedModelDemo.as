package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel
{
	import away3d.animators.data.SkeletonAnimation;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.skeleton.SkeletonJoint;
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.library.AssetLibrary;
	import away3d.lights.PointLight;
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
		
		/*
		[Embed(source="/../assets/characters/player/body.png")]
		private var BodyAlbedo : Class;
		
		[Embed(source="/../assets/characters/player/body_s.png")]
		private var BodySpec : Class;
		
		[Embed(source="/../assets/characters/player/body_local.png")]
		private var BodyNorms : Class;
		
		[Embed(source="/../assets/characters/player/arm2.png")]
		private var ArmAlbedo : Class;
		
		[Embed(source="/../assets/characters/player/arm2_s.png")]
		private var ArmSpec : Class;
		
		[Embed(source="/../assets/characters/player/arm2_local.png")]
		private var ArmNorms : Class;
		
		[Embed(source="/../assets/characters/player/playerhead.png")]
		private var HeadAlbedo : Class;
		
		[Embed(source="/../assets/characters/player/playerhead_s.png")]
		private var HeadSpec : Class;
		
		[Embed(source="/../assets/characters/player/playerhead_local.png")]
		private var HeadNorms : Class;
		
		[Embed(source="/../assets/characters/player/teethdeadb.png")]
		private var TeethAlbedo : Class;
		
		[Embed(source="/../assets/characters/player/teeth_local.png")]
		private var TeethNorms : Class;
		
		[Embed(source="/../assets/characters/player/green.png")]
		private var Eye : Class;
		*/
		
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var mesh:Mesh;
		
		private var _bodyMaterial:TextureMaterial;
		private var _armsMaterial:TextureMaterial;
		private var _headMaterial:TextureMaterial;
		private var _teethMaterial:TextureMaterial;
		private var _eyeMaterial:TextureMaterial;
		
		
		private var _light:PointLight;
		private var _light2:PointLight;
		private var _light3:PointLight;
		
		private var animationController:RiggedModelAnimationControllerByRotation;
		
		private var kinect:Kinect;
		
		private var rgbBitmap:Bitmap;
		private var rgbSkeletonContainer:Sprite;
		
		override protected function startDemoImplementation():void
		{
			trace("[RiggedModelDemo] Start Demo");
			
			scene = new Scene3D();
			camera = new Camera3D();
			
			view = new View3D();
			view.antiAlias = 4;
			view.backgroundColor = 0xFFFFFF;
			view.scene = scene;
			view.camera = camera;
			addChild(view);
			
			AssetLibrary.enableParser(RotatedMD5MeshParser);
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, assetCompleteHandler, false, 0, true);
			
			//you'll need a mesh in T-pose for rotation based rigging to work!
			
			AssetLibrary.load(new URLRequest("assets/characters/hellknight/hellknight.md5mesh"));
			//AssetLibrary.load(new URLRequest("assets/characters/player/player.md5mesh"));
		}
		
		protected function assetCompleteHandler(event:AssetEvent):void
		{
			trace("assetCompleteHandler");
			if (!(event.asset is Mesh)) return;
			
			trace("create mesh");
			
			mesh = Mesh(event.asset);
			
			camera.z = mesh.maxZ * -4;
			camera.y = mesh.maxY / 2;
			
			initLights();
			initMaterials();
			
			mesh.material = _bodyMaterial;
			
			/*
			mesh.subMeshes[0].material = _headMaterial;
			mesh.subMeshes[1].material = _teethMaterial;
			mesh.subMeshes[2].material = _eyeMaterial;
			mesh.subMeshes[3].material = _eyeMaterial;
			mesh.subMeshes[6].material = _armsMaterial;
			*/
			
			scene.addChild(mesh);
			
			var i:uint = 0;
			for each(var skeletonJoint:away3d.animators.skeleton.SkeletonJoint in (mesh.animationState.animation as SkeletonAnimation).skeleton.joints)
			{
				trace(i, skeletonJoint.name, skeletonJoint.parentIndex);
				i++;
			}
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			
			var jointMapping:Vector.<Number> = Vector.<Number>([
			/*
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Head"), 			// XN_SKEL_HEAD
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Neck"),			// XN_SKEL_NECK
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Chest"),			// XN_SKEL_TORSO
				
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Luparm"), 		// XN_SKEL_LEFT_SHOULDER
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Lloarm"),			// XN_SKEL_LEFT_ELBOW
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Lhand"),			// XN_SKEL_LEFT_HAND
				
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Ruparm"), 		// XN_SKEL_RIGHT_SHOULDER
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Rloarm"),			// XN_SKEL_RIGHT_ELBOW
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Rhand"), 		// XN_SKEL_RIGHT_HAND
				
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Lupleg"),			// XN_SKEL_LEFT_HIP
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Lloleg"),			// XN_SKEL_LEFT_KNEE
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Lball_r"),			// XN_SKEL_LEFT_FOOT
				
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Rupleg"),			// XN_SKEL_RIGHT_HIP
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Rloleg"),			// XN_SKEL_RIGHT_KNEE
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Rball_r")			// XN_SKEL_RIGHT_FOOT
			*/
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
			
			animationController = new RiggedModelAnimationControllerByRotation(jointMapping, SkeletonAnimationState(mesh.animationState));
			
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
			if(animationController.kinectUser == null)
			{
				animationController.kinectUser = event.users[0];
			}
		}
		
		protected function usersWithSkeletonRemovedHandler(event:UserEvent):void
		{
			trace("[RiggedModelDemo] User With Skeleton Removed", event.users);
			for each(var removedUser:User in event.users)
			{
				if(removedUser == animationController.kinectUser)
				{
					animationController.kinectUser = null;
					break;
				}
			}
			if(kinect.usersWithSkeleton.length > 0)
			{
				animationController.kinectUser = kinect.usersWithSkeleton[0];
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
			
			_bodyMaterial = new TextureMaterial(new BitmapTexture(new BodyAlbedo().bitmapData));
			_bodyMaterial.lightPicker = lightPicker;
			_bodyMaterial.ambientColor = 0x101020;
			_bodyMaterial.ambient = 1;
			_bodyMaterial.specularMap = new BitmapTexture(new BodySpec().bitmapData);
			_bodyMaterial.normalMap = new BitmapTexture(new BodyNorms().bitmapData);
			/*
			_armsMaterial = new TextureMaterial(new BitmapTexture(new ArmAlbedo().bitmapData));
			_armsMaterial.lightPicker = lightPicker;
			_armsMaterial.ambientColor = 0x101020;
			_armsMaterial.ambient = 1;
			_armsMaterial.specularMap = new BitmapTexture(new ArmSpec().bitmapData);
			_armsMaterial.normalMap = new BitmapTexture(new ArmNorms().bitmapData);
			
			_headMaterial = new TextureMaterial(new BitmapTexture(new HeadAlbedo().bitmapData));
			_headMaterial.lightPicker = lightPicker;
			_headMaterial.ambientColor = 0x101020;
			_headMaterial.ambient = 1;
			_headMaterial.specularMap = new BitmapTexture(new HeadSpec().bitmapData);
			_headMaterial.normalMap = new BitmapTexture(new HeadNorms().bitmapData);
			
			_teethMaterial = new TextureMaterial(new BitmapTexture(new TeethAlbedo().bitmapData));
			_teethMaterial.lightPicker = lightPicker;
			_teethMaterial.ambientColor = 0x101020;
			_teethMaterial.ambient = 1;
			//			_teethMaterial.specular = 0;
			_teethMaterial.normalMap = new BitmapTexture(new TeethNorms().bitmapData);
			
			_eyeMaterial = new TextureMaterial(new BitmapTexture(new Eye().bitmapData));
			_eyeMaterial.lightPicker = lightPicker;
			*/
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			view.render();
			if(rgbSkeletonContainer != null && kinect != null)
			{
				rgbSkeletonContainer.graphics.clear();
				for each(var user:User in kinect.usersWithSkeleton)
				{
					drawRGBBone(user.leftHand, user.leftElbow);
					drawRGBBone(user.leftElbow, user.leftShoulder);
					drawRGBBone(user.leftShoulder, user.neck);
					drawRGBBone(user.leftShoulder, user.torso);
					
					drawRGBBone(user.rightHand, user.rightElbow);
					drawRGBBone(user.rightElbow, user.rightShoulder);
					drawRGBBone(user.rightShoulder, user.neck);
					drawRGBBone(user.rightShoulder, user.torso);
					
					drawRGBBone(user.head, user.neck);
					
					drawRGBBone(user.torso, user.leftHip);
					drawRGBBone(user.leftHip, user.leftKnee);
					drawRGBBone(user.leftKnee, user.leftFoot);
					
					drawRGBBone(user.torso, user.rightHip);
					drawRGBBone(user.rightHip, user.rightKnee);
					drawRGBBone(user.rightKnee, user.rightFoot);
					
					for each(var joint:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint in user.skeletonJoints)
					{
						rgbSkeletonContainer.graphics.lineStyle(2, 0xFFFFFF);
						rgbSkeletonContainer.graphics.beginFill(0xFF0000);
						rgbSkeletonContainer.graphics.drawCircle(joint.rgbPosition.x, joint.rgbPosition.y, 2);
						rgbSkeletonContainer.graphics.endFill();
					}
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