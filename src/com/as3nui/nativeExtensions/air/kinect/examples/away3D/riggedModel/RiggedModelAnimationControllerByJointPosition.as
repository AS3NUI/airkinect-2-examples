package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel
{
	import away3d.animators.AnimatorBase;
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
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	use namespace arcane;
	
	public class RiggedModelAnimationControllerByJointPosition extends AnimatorBase
	{
		private var _kinectUser:User;
		
		private var _jointMapping:Dictionary;
		private var _skeleton:away3d.animators.skeleton.Skeleton;
		private var _globalMatrices:Vector.<Matrix3D>;
		private var _globalWisdom:Vector.<Boolean>;
		private var _localPoses:Vector.<JointPose>;
		private var _globalPoses:Vector.<JointPose>;
		private var _bindPoses:Vector.<Matrix3D>;
		private var _jointSmoothing:Number = .1;
		private var _posSmoothing:Number = .8;
		private var _bindPoseOrientationsOfTrackedJoints:Dictionary;
		private var _bindShoulderOrientation:Vector3D;
		private var _bindSpineOrientation:Vector3D;
		private var _trackingCenter:Vector3D;
		private var _trackScale:Number = .1;
		private var _quaternionPool:ObjectPool;
		private var _vector3DPool:ObjectPool;
		private var _skeletonAnimationState:SkeletonAnimationState;
		
		private var _rootLocalPose:JointPose;
		
		public function RiggedModelAnimationControllerByJointPosition(user:User, jointMapping:Dictionary, target:SkeletonAnimationState)
		{
			super();
			_kinectUser = user;
			_quaternionPool = ObjectPool.getGlobalPool(Quaternion);
			_vector3DPool = ObjectPool.getGlobalPool(Vector3D);
			_jointMapping = jointMapping;
			
			_trackingCenter = new Vector3D();
			_skeletonAnimationState = target;
			
			SkeletonAnimationState(target).arcane::globalInput = true;
			
			initSkeleton();
			initBindPoseOrientations();
			
			start();
		}
		
		override protected function updateAnimation(realDT:Number, scaledDT:Number):void
		{
			if(_kinectUser != null)
			{
				updatePose();
			}
		}
		
		private function initSkeleton():void
		{
			var joint:away3d.animators.skeleton.SkeletonJoint;
			var q1:Quaternion = Quaternion(_quaternionPool.alloc()),
				q2:Quaternion = Quaternion(_quaternionPool.alloc());
			var bind:Matrix3D = new Matrix3D();
			var parentBind:Matrix3D = new Matrix3D();
			
			_skeleton = SkeletonAnimation(_skeletonAnimationState.animation).skeleton;
			
			_localPoses = new Vector.<JointPose>(_skeleton.numJoints, true);
			_globalPoses = new Vector.<JointPose>(_skeleton.numJoints, true);
			_globalWisdom = new Vector.<Boolean>(_skeleton.numJoints, true);
			_bindPoses = new Vector.<Matrix3D>(_skeleton.numJoints, true);
			_globalMatrices = new Vector.<Matrix3D>(_skeleton.numJoints, true);
			
			for (var i:int = 0; i < _skeleton.numJoints; ++i) 
			{
				joint = _skeleton.joints[i];
				_localPoses[i] = new JointPose();
				_globalPoses[i] = new JointPose();
				_globalPoses[i].orientation = new Quaternion();
				_globalPoses[i].translation = new Vector3D();
				bind = new Matrix3D(joint.inverseBindPose);
				bind.invert();
				_bindPoses[i] = bind;
				
				_localPoses[i].orientation = new Quaternion();
				if (joint.parentIndex < 0)
				{
					_rootLocalPose = _localPoses[i];
					_localPoses[i].orientation.fromMatrix(bind);
					_localPoses[i].translation = bind.position;
				}
				else 
				{
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
		
		private function initBindPoseOrientations():void
		{
			_bindPoseOrientationsOfTrackedJoints = new Dictionary();
			
			_bindShoulderOrientation = new Vector3D();
			_bindSpineOrientation = new Vector3D();
			
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_SHOULDER, _bindShoulderOrientation);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.TORSO, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.NECK, _bindSpineOrientation);
			
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.NECK, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.HEAD);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_ELBOW);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_ELBOW, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HAND);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_ELBOW);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_ELBOW, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HAND);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HIP, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_KNEE);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_KNEE, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_FOOT);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HIP, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_KNEE);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_KNEE, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_FOOT);
		}
		
		private function getSimpleBindOrientation(sourceKinectJointName:String, targetKinectJointName:String, storeVec:Vector3D = null):void
		{
			var pos1:Vector3D;
			var pos2:Vector3D;
			var mapIndex1:int = _jointMapping[sourceKinectJointName];
			var mapIndex2:int = _jointMapping[targetKinectJointName];
			var mtx:Matrix3D = new Matrix3D();
			
			if (mapIndex1 < 0 || mapIndex2 < 0) return;
			
			pos1 = _bindPoses[mapIndex1].position;
			pos2 = _bindPoses[mapIndex2].position;
			
			if (!storeVec)
				(_bindPoseOrientationsOfTrackedJoints[sourceKinectJointName] = pos2.subtract(pos1)).normalize();
			else {
				storeVec.x = pos2.x - pos1.x;
				storeVec.y = pos2.y - pos1.y;
				storeVec.z = pos2.z - pos1.z;
				storeVec.normalize();
			}
		}
		
		private function updatePose():void
		{
			updateCentralPosition();
			updateTorso();
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.NECK, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.HEAD);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_ELBOW);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_ELBOW, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HAND);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_ELBOW);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_ELBOW, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HAND);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HIP, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_KNEE);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_KNEE, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_FOOT);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HIP, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_KNEE);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_KNEE, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_FOOT);
			
			for each(var jointName:String in _kinectUser.skeletonJointNames)
			{
				var mapIndex:int = _jointMapping[jointName];
				if(mapIndex >= 0 && _kinectUser.getJointByName(jointName).positionConfidence < .5)
					_globalWisdom[mapIndex] = false;
			}
			
			updateMatrices();
		}
		
		private function getPosition(kinectSkeletonJoint:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint):Vector3D
		{
			var p:Vector3D = kinectSkeletonJoint.position.world.clone();
			//p.x *= -1;
			return p;
		}
		
		private function updateCentralPosition():void
		{
			var center:Vector3D = getPosition(_kinectUser.torso);
			var tr:Vector3D = _rootLocalPose.translation;
			var invPosSmoothing:Number = 1 - _posSmoothing;
			
			tr.x = tr.x + ((center.x - _trackingCenter.x) * _trackScale - tr.x) * invPosSmoothing;
			tr.y = tr.y + ((center.y - _trackingCenter.y) * _trackScale - tr.y) * invPosSmoothing;
			tr.z = tr.z + ((center.z - _trackingCenter.z) * _trackScale - tr.z) * invPosSmoothing;
		}
		
		private function updateTorso():void
		{
			var mapIndex:int = _jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.TORSO];
			var axis:Vector3D;
			var shoulderDir:Vector3D, spineDir:Vector3D;
			var torsoYawRotation:Quaternion;
			var torsoPitchRotation:Quaternion;
			var torsoRollRotation:Quaternion;
			var temp:Quaternion;
			var pos1:Vector3D, pos2:Vector3D;
			
			if (mapIndex < 0) return;
			
			_globalWisdom[mapIndex] = true;
			
			shoulderDir = getPosition(_kinectUser.leftShoulder).subtract(getPosition(_kinectUser.rightShoulder));
			shoulderDir.y = 0.0;
			shoulderDir.normalize();
			axis = _bindShoulderOrientation.crossProduct(shoulderDir);
			torsoYawRotation = Quaternion(_quaternionPool.alloc());
			torsoYawRotation.fromAxisAngle(axis, Math.acos(_bindShoulderOrientation.dotProduct(shoulderDir)));
			
			pos1 = getPosition(_kinectUser.neck);
			pos2 = getPosition(_kinectUser.torso);
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
		
		private function updateSimpleJoint(sourceKinectJointName:String, targetKinectJointName:String):void
		{
			var bindDir:Vector3D, currDir:Vector3D, axis:Vector3D;
			var mapIndex:int = _jointMapping[sourceKinectJointName];
			var orientation:Quaternion;
			var sourceKinectJoint:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint = _kinectUser.getJointByName(sourceKinectJointName);
			var targetKinectJoint:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint = _kinectUser.getJointByName(targetKinectJointName);
			
			if (mapIndex < 0) return;
			
			currDir = getPosition(targetKinectJoint).subtract(getPosition(sourceKinectJoint));
			currDir.normalize();
			bindDir = _bindPoseOrientationsOfTrackedJoints[sourceKinectJointName];
			
			axis = bindDir.crossProduct(currDir);
			axis.normalize();
			
			_globalWisdom[mapIndex] = true;
			orientation = _globalPoses[mapIndex].orientation;
			orientation.fromAxisAngle(axis, Math.acos(bindDir.dotProduct(currDir)));
		}
		
		private function updateMatrices():void
		{
			var j:int;
			var raw:Vector.<Number>;
			var joint:away3d.animators.skeleton.SkeletonJoint;
			var mtx:Matrix3D = new Matrix3D();
			var mtx2:Matrix3D = new Matrix3D();
			var parentIndex:int;
			var globalPose:JointPose, localPose:JointPose, parentPose:JointPose;
			var globalOrientation:Quaternion, localOrientation:Quaternion, parentOrientation:Quaternion;
			var globalTranslation:Vector3D, localTranslation:Vector3D, parentTranslation:Vector3D;
			// todo: check if globalMatrices is correct (was: jointMatrices)
			var jointMatrices:Vector.<Number> = SkeletonAnimationState(_skeletonAnimationState).globalMatrices;
			
			for (var i:int = 0; i < _skeleton.numJoints; ++i) {
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
				
				var smInv:Number = 1 - _jointSmoothing;
				
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