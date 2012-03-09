package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel
{
	import away3d.animators.data.SkeletonAnimation;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.skeleton.JointPose;
	import away3d.animators.skeleton.Skeleton;
	import away3d.animators.skeleton.SkeletonJoint;
	import away3d.arcane;
	import away3d.core.math.Quaternion;
	
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.derschmale.data.ObjectPool;
	import com.derschmale.openni.XnSkeletonJoint;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	// http://groups.google.com/group/openni-dev/browse_thread/thread/9119214f36a28c8f
	
	use namespace arcane;
	
	public class RiggedModelAnimationControllerByPosition extends RiggedModelAnimationController
	{
		private static const NUM_TRACKED_JOINTS : int = 15;
		
		private var _jointMapping : Vector.<Number>;
		private var _skeleton : away3d.animators.skeleton.Skeleton;
		private var _globalMatrices : Vector.<Matrix3D>;
		private var _globalWisdom : Vector.<Boolean>;
		private var _localPoses : Vector.<JointPose>;
		private var _globalPoses : Vector.<JointPose>;
		private var _trackedPositions : Vector.<Vector3D>;
		private var _positionConfidences : Vector.<Number>;
		private var _bindPoses : Vector.<Matrix3D>;
		private var _jointSmoothing : Number = .1;
		private var _posSmoothing : Number = .8;
		private var _bindPoseOrientations : Vector.<Vector3D>;
		private var _bindShoulderOrientation : Vector3D;
		private var _bindSpineOrientation : Vector3D;
		private var _trackingCenter : Vector3D;
		private var _trackScale : Number = .1;
		private var _quaternionPool:ObjectPool;
		private var _vector3DPool:ObjectPool;
		private var _skeletonAnimationState : SkeletonAnimationState;
		
		public function RiggedModelAnimationControllerByPosition(jointMapping : Vector.<Number>, target : SkeletonAnimationState)
		{
			super();
			_quaternionPool = ObjectPool.getGlobalPool(Quaternion);
			_vector3DPool = ObjectPool.getGlobalPool(Vector3D);
			_jointMapping = jointMapping;
			
			_trackingCenter = new Vector3D();
			_trackedPositions = new Vector.<Vector3D>(NUM_TRACKED_JOINTS, true);
			_positionConfidences = new Vector.<Number>(NUM_TRACKED_JOINTS, true);
			_skeletonAnimationState = target;
			
			SkeletonAnimationState(target).arcane::globalInput = true;
			
			initSkeleton();
			initBindPoseOrientations();
			
			start();
		}
		
		public function centerOnUser() : void
		{
			_trackingCenter.x = _trackedPositions[XnSkeletonJoint.TORSO].x;
			_trackingCenter.y = _trackedPositions[XnSkeletonJoint.TORSO].y;
			_trackingCenter.z = _trackedPositions[XnSkeletonJoint.TORSO].z;	// at least a meter away
		}
		
		public function drawSkeleton(target : Sprite, scale : Number = .25) : void
		{
			var g : Graphics = target.graphics;
			g.clear();
			drawLimb(g, XnSkeletonJoint.LEFT_SHOULDER, XnSkeletonJoint.RIGHT_SHOULDER, scale, false);
			drawLimb(g, XnSkeletonJoint.TORSO, XnSkeletonJoint.LEFT_SHOULDER, scale);
			drawLimb(g, XnSkeletonJoint.RIGHT_SHOULDER, XnSkeletonJoint.TORSO, scale, false);
			drawLimb(g, XnSkeletonJoint.LEFT_HIP, XnSkeletonJoint.RIGHT_HIP, scale, false);
			drawLimb(g, XnSkeletonJoint.LEFT_HIP, XnSkeletonJoint.TORSO, scale, false);
			drawLimb(g, XnSkeletonJoint.RIGHT_HIP, XnSkeletonJoint.TORSO, scale, false);
			drawLimb(g, XnSkeletonJoint.NECK, XnSkeletonJoint.HEAD, scale);
			drawLimb(g, XnSkeletonJoint.LEFT_SHOULDER, XnSkeletonJoint.LEFT_ELBOW, scale);
			drawLimb(g, XnSkeletonJoint.LEFT_ELBOW, XnSkeletonJoint.LEFT_HAND, scale);
			drawLimb(g, XnSkeletonJoint.RIGHT_SHOULDER, XnSkeletonJoint.RIGHT_ELBOW, scale);
			drawLimb(g, XnSkeletonJoint.RIGHT_ELBOW, XnSkeletonJoint.RIGHT_HAND, scale);
			drawLimb(g, XnSkeletonJoint.LEFT_HIP, XnSkeletonJoint.LEFT_KNEE, scale);
			drawLimb(g, XnSkeletonJoint.LEFT_KNEE, XnSkeletonJoint.LEFT_FOOT, scale);
			drawLimb(g, XnSkeletonJoint.RIGHT_HIP, XnSkeletonJoint.RIGHT_KNEE, scale);
			drawLimb(g, XnSkeletonJoint.RIGHT_KNEE, XnSkeletonJoint.RIGHT_FOOT, scale);
		}
		
		override protected function updateAnimation(realDT : Number, scaledDT : Number) : void
		{
			if(kinectUser != null)
			{
				updatePose();
			}
		}
		
		private function initSkeleton() : void
		{
			var joint : away3d.animators.skeleton.SkeletonJoint;
			var q1 : Quaternion = Quaternion(_quaternionPool.alloc()),
				q2 : Quaternion = Quaternion(_quaternionPool.alloc());
			var bind : Matrix3D = new Matrix3D();
			var parentBind : Matrix3D = new Matrix3D();
			
			_skeleton = SkeletonAnimation(_skeletonAnimationState.animation).skeleton;
			
			_localPoses = new Vector.<JointPose>(_skeleton.numJoints, true);
			_globalPoses = new Vector.<JointPose>(_skeleton.numJoints, true);
			_globalWisdom = new Vector.<Boolean>(_skeleton.numJoints, true);
			_bindPoses = new Vector.<Matrix3D>(_skeleton.numJoints, true);
			_globalMatrices = new Vector.<Matrix3D>(_skeleton.numJoints, true);
			
			for (var i : int = 0; i < _skeleton.numJoints; ++i) {
				// if index is in joint map, we know its global orientation
				joint = _skeleton.joints[i];
				_localPoses[i] = new JointPose();
				_globalPoses[i] = new JointPose();
				_globalPoses[i].orientation = new Quaternion();
				_globalPoses[i].translation = new Vector3D();
				bind = new Matrix3D(joint.inverseBindPose);
				bind.invert();
				_bindPoses[i] = bind;
				
				_localPoses[i].orientation = new Quaternion();
				if (joint.parentIndex < 0) {
					_localPoses[i].orientation.fromMatrix(bind);
					_localPoses[i].translation = bind.position;
				}
				else {
					parentBind.rawData = _skeleton.joints[joint.parentIndex].inverseBindPose;
					
					q1.fromMatrix(parentBind);
					q1.normalize();
					q2.fromMatrix(bind);
					q2.normalize();
					_localPoses[i].orientation.multiply(q1, q2);
					_localPoses[i].translation = parentBind.transformVector(bind.position);
				}
			}
			
			_quaternionPool.free(q1);
			_quaternionPool.free(q2);
		}
		
		private function initBindPoseOrientations() : void
		{
			_bindPoseOrientations = new Vector.<Vector3D>(NUM_TRACKED_JOINTS, true);
			
			_bindShoulderOrientation = new Vector3D();
			_bindSpineOrientation = new Vector3D();
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_SHOULDER, XnSkeletonJoint.RIGHT_SHOULDER, _bindShoulderOrientation);
			getSimpleBindOrientation(XnSkeletonJoint.TORSO, XnSkeletonJoint.NECK, _bindSpineOrientation);
			
			getSimpleBindOrientation(XnSkeletonJoint.NECK, XnSkeletonJoint.HEAD);
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_SHOULDER, XnSkeletonJoint.LEFT_ELBOW);
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_ELBOW, XnSkeletonJoint.LEFT_HAND);
			getSimpleBindOrientation(XnSkeletonJoint.RIGHT_SHOULDER, XnSkeletonJoint.RIGHT_ELBOW);
			getSimpleBindOrientation(XnSkeletonJoint.RIGHT_ELBOW, XnSkeletonJoint.RIGHT_HAND);
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_HIP, XnSkeletonJoint.LEFT_KNEE);
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_KNEE, XnSkeletonJoint.LEFT_FOOT);
			getSimpleBindOrientation(XnSkeletonJoint.RIGHT_HIP, XnSkeletonJoint.RIGHT_KNEE);
			getSimpleBindOrientation(XnSkeletonJoint.RIGHT_KNEE, XnSkeletonJoint.RIGHT_FOOT);
		}
		
		private function getSimpleBindOrientation(src : int, tgt : int, storeVec : Vector3D = null) : void
		{
			var pos1 : Vector3D;
			var pos2 : Vector3D;
			var mapIndex1 : int = _jointMapping[src];
			var mapIndex2 : int = _jointMapping[tgt];
			var mtx : Matrix3D = new Matrix3D();
			
			if (mapIndex1 < 0 || mapIndex2 < 0) return;
			
			pos1 = _bindPoses[mapIndex1].position;
			pos2 = _bindPoses[mapIndex2].position;
			
			if (!storeVec)
				(_bindPoseOrientations[src] = pos2.subtract(pos1)).normalize();
			else {
				storeVec.x = pos2.x - pos1.x;
				storeVec.y = pos2.y - pos1.y;
				storeVec.z = pos2.z - pos1.z;
				storeVec.normalize();
			}
		}
		
		private function updatePose() : void
		{
			setPosesFromKinectSkeleton();
			updateCentralPosition();
			updateTorso();
			updateSimpleJoint(XnSkeletonJoint.NECK, XnSkeletonJoint.HEAD);
			updateSimpleJoint(XnSkeletonJoint.LEFT_SHOULDER, XnSkeletonJoint.LEFT_ELBOW);
			updateSimpleJoint(XnSkeletonJoint.LEFT_ELBOW, XnSkeletonJoint.LEFT_HAND);
			updateSimpleJoint(XnSkeletonJoint.RIGHT_SHOULDER, XnSkeletonJoint.RIGHT_ELBOW);
			updateSimpleJoint(XnSkeletonJoint.RIGHT_ELBOW, XnSkeletonJoint.RIGHT_HAND);
			updateSimpleJoint(XnSkeletonJoint.LEFT_HIP, XnSkeletonJoint.LEFT_KNEE);
			updateSimpleJoint(XnSkeletonJoint.LEFT_KNEE, XnSkeletonJoint.LEFT_FOOT);
			updateSimpleJoint(XnSkeletonJoint.RIGHT_HIP, XnSkeletonJoint.RIGHT_KNEE);
			updateSimpleJoint(XnSkeletonJoint.RIGHT_KNEE, XnSkeletonJoint.RIGHT_FOOT);
			
			for (var i : int = 0; i < NUM_TRACKED_JOINTS; ++i) {
				var mapIndex : int = _jointMapping[i];
				if (mapIndex >= 0 && _positionConfidences[i] < .5)
					_globalWisdom[mapIndex] = false;
			}
			
			updateMatrices();
		}
		
		private function updateCentralPosition() : void
		{
			var center : Vector3D = _trackedPositions[XnSkeletonJoint.TORSO];
			var tr : Vector3D = _localPoses[0].translation;
			var invPosSmoothing : Number = 1 - _posSmoothing;
			
			tr.x = tr.x + ((center.x - _trackingCenter.x) * _trackScale - tr.x) * invPosSmoothing;
			tr.y = tr.y + ((center.y - _trackingCenter.y) * _trackScale - tr.y) * invPosSmoothing;
			tr.z = tr.z + ((center.z - _trackingCenter.z) * _trackScale - tr.z) * invPosSmoothing;
		}
		
		private function updateTorso() : void
		{
			var mapIndex : int = _jointMapping[XnSkeletonJoint.TORSO];
			var axis : Vector3D;
			var shoulderDir : Vector3D, spineDir : Vector3D;
			var torsoYawRotation : Quaternion;
			var torsoPitchRotation : Quaternion;
			var torsoRollRotation : Quaternion;
			var temp : Quaternion;
			var pos1 : Vector3D, pos2 : Vector3D;
			
			if (mapIndex < 0) return;
			
			_globalWisdom[mapIndex] = true;
			
			// torso
			shoulderDir = _trackedPositions[XnSkeletonJoint.RIGHT_SHOULDER].subtract(_trackedPositions[XnSkeletonJoint.LEFT_SHOULDER]);
			shoulderDir.y = 0.0;
			shoulderDir.normalize();
			axis = _bindShoulderOrientation.crossProduct(shoulderDir);
			torsoYawRotation = Quaternion(_quaternionPool.alloc());
			torsoYawRotation.fromAxisAngle(axis, Math.acos(_bindShoulderOrientation.dotProduct(shoulderDir)));
			
			pos1 = _trackedPositions[XnSkeletonJoint.NECK];
			pos2 = _trackedPositions[XnSkeletonJoint.TORSO];
			spineDir = Vector3D(_vector3DPool.alloc());
			spineDir.x = 0.0;
			spineDir.y = pos1.y - pos2.y;
			spineDir.z = pos1.z - pos2.z;
			spineDir.normalize();
			axis = _bindSpineOrientation.crossProduct(spineDir);
			torsoPitchRotation = Quaternion(_quaternionPool.alloc());
			torsoPitchRotation.fromAxisAngle(axis, Math.acos(_bindSpineOrientation.dotProduct(spineDir)));
			
			spineDir.x = pos1.x - pos2.x;
			spineDir.y = pos1.y - pos2.y;
			spineDir.z = 0;
			spineDir.normalize();
			axis = _bindSpineOrientation.crossProduct(spineDir);
			torsoRollRotation = Quaternion(_quaternionPool.alloc());
			torsoRollRotation.fromAxisAngle(axis, Math.acos(_bindSpineOrientation.dotProduct(spineDir)));
			
			temp = Quaternion(_quaternionPool.alloc());
			temp.multiply(torsoPitchRotation, torsoRollRotation);
			
			_globalPoses[mapIndex].orientation.multiply(torsoYawRotation, temp);
			
			_quaternionPool.free(temp);
			_quaternionPool.free(torsoPitchRotation);
			_quaternionPool.free(torsoRollRotation);
			_quaternionPool.free(torsoYawRotation);
			_vector3DPool.free(spineDir);
		}
		
		private function updateSimpleJoint(srcJoint : int, tgtJoint : int) : void
		{
			var bindDir : Vector3D, currDir : Vector3D, axis : Vector3D;
			var mapIndex : int = _jointMapping[srcJoint];
			var orientation : Quaternion;
			
			if (mapIndex < 0) return;
			
			currDir = _trackedPositions[tgtJoint].subtract(_trackedPositions[srcJoint]);
			currDir.normalize();
			bindDir = _bindPoseOrientations[srcJoint];
			
			axis = bindDir.crossProduct(currDir);
			axis.normalize();
			
			_globalWisdom[mapIndex] = true;
			orientation = _globalPoses[mapIndex].orientation;
			orientation.fromAxisAngle(axis, Math.acos(bindDir.dotProduct(currDir)));
		}
		
		private function setPosesFromKinectSkeleton() : void
		{
			setPoseForJoint(XnSkeletonJoint.HEAD, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.HEAD);
			setPoseForJoint(XnSkeletonJoint.NECK, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.NECK);
			setPoseForJoint(XnSkeletonJoint.TORSO, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.TORSO);
			
			setPoseForJoint(XnSkeletonJoint.LEFT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_SHOULDER);
			setPoseForJoint(XnSkeletonJoint.LEFT_ELBOW, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_ELBOW);
			setPoseForJoint(XnSkeletonJoint.LEFT_HAND, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HAND);
			
			setPoseForJoint(XnSkeletonJoint.RIGHT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_SHOULDER);
			setPoseForJoint(XnSkeletonJoint.RIGHT_ELBOW, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_ELBOW);
			setPoseForJoint(XnSkeletonJoint.RIGHT_HAND, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HAND);
			
			setPoseForJoint(XnSkeletonJoint.LEFT_HIP, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HIP);
			setPoseForJoint(XnSkeletonJoint.LEFT_KNEE, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_KNEE);
			setPoseForJoint(XnSkeletonJoint.LEFT_FOOT, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_FOOT);
			
			setPoseForJoint(XnSkeletonJoint.RIGHT_HIP, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HIP);
			setPoseForJoint(XnSkeletonJoint.RIGHT_KNEE, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_KNEE);
			setPoseForJoint(XnSkeletonJoint.RIGHT_FOOT, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_FOOT);
		}
		
		private function setPoseForJoint(targetIndex:int, kinectSkeletonJointName:String):void
		{
			var pos : Vector3D;
			var joint:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint = kinectUser.getJointByName(kinectSkeletonJointName);
			pos = (_trackedPositions[targetIndex] ||= new Vector3D());
			pos.x = joint.position.x;
			pos.y = joint.position.y;
			pos.z = joint.position.z;
			_positionConfidences[targetIndex] = joint.positionConfidence;
		}
		
		private function drawLimb(target : Graphics, startIndex : int, endIndex : int, scale : Number, drawFirstPoint : Boolean = true) : void
		{
			var pos1 : Vector3D = _trackedPositions[startIndex];
			var pos2 : Vector3D = _trackedPositions[endIndex];
			
			if (_positionConfidences[startIndex] < .5) return;
			
			if (drawFirstPoint) {
				target.beginFill(0x0000ff, pos1.z / 1000);
				target.drawCircle(pos1.x * scale, -pos1.y * scale, 3);
				target.endFill();
			}
			
			target.lineStyle(1, 0xff00ff);
			target.moveTo(pos1.x * scale, -pos1.y * scale);
			target.lineTo(pos2.x * scale, -pos2.y * scale);
			target.lineStyle();
		}
		
		private function updateMatrices() : void
		{
			var j : int;
			var raw : Vector.<Number>;
			var joint : away3d.animators.skeleton.SkeletonJoint;
			var mtx : Matrix3D = new Matrix3D();
			var mtx2 : Matrix3D = new Matrix3D();
			var parentIndex : int;
			var globalPose : JointPose, localPose : JointPose, parentPose : JointPose;
			var globalOrientation : Quaternion, localOrientation : Quaternion, parentOrientation : Quaternion;
			var globalTranslation : Vector3D, localTranslation : Vector3D, parentTranslation : Vector3D;
			// todo: check if globalMatrices is correct (was: jointMatrices)
			var jointMatrices : Vector.<Number> = SkeletonAnimationState(_skeletonAnimationState).globalMatrices;
			
			for (var i : int = 0; i < _skeleton.numJoints; ++i) {
				joint = _skeleton.joints[i];
				parentIndex = joint.parentIndex;
				globalPose = _globalPoses[i];
				localPose = _localPoses[i];
				
				if (parentIndex < 0)
					globalPose.copyFrom(localPose);
				else {
					globalOrientation = globalPose.orientation;
					globalTranslation = globalPose.translation;
					localOrientation = localPose.orientation;
					localTranslation = localPose.translation;
					
					parentPose = _globalPoses[parentIndex];
					parentOrientation = parentPose.orientation;
					parentTranslation = parentPose.translation;
					parentPose.orientation.rotatePoint(localTranslation, globalTranslation);
					globalTranslation.x += parentTranslation.x;
					globalTranslation.y += parentTranslation.y;
					globalTranslation.z += parentTranslation.z;
					
					if (!_globalWisdom[i]) {
						globalOrientation.multiply(parentOrientation, localOrientation);
						globalOrientation.normalize();
					}
					else {
						_bindPoses[i].copyToMatrix3D(mtx)
						mtx.append(globalOrientation.toMatrix3D(mtx2));
						globalOrientation.fromMatrix(mtx);
					}
				}
				
				mtx.rawData = joint.inverseBindPose;
				mtx.append(globalPose.toMatrix3D(mtx2));
				raw = mtx.rawData;
				
				var smInv : Number = 1 - _jointSmoothing;
				
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[0] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[4] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[8] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[12] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[1] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[5] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[9] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[13] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[2] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[6] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[10] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[14] * smInv;
				++j;
			}
			
			SkeletonAnimationState(_skeletonAnimationState).invalidateState();
			SkeletonAnimationState(_skeletonAnimationState).arcane::validateGlobalMatrices();
		}
	}
}