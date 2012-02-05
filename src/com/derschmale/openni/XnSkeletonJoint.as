package com.derschmale.openni
{
	import com.as3nui.nativeExtensions.air.kinect.constants.JointNames;

	public class XnSkeletonJoint
	{
		public static const HEAD : int = 0;
		public static const NECK : int = 1;
		public static const TORSO : int = 2;

		public static const LEFT_SHOULDER : int = 3;
		public static const LEFT_ELBOW : int = 4;
		public static const LEFT_HAND : int = 5;

		public static const RIGHT_SHOULDER : int = 6;
		public static const RIGHT_ELBOW : int = 7;
		public static const RIGHT_HAND : int = 8;

		public static const LEFT_HIP : int = 9;
		public static const LEFT_KNEE : int = 10;
		public static const LEFT_FOOT : int = 11;

		public static const RIGHT_HIP : int = 12;
		public static const RIGHT_KNEE : int = 13;
		public static const RIGHT_FOOT : int = 14;
		
		public static const NAMES_BY_INDEX:Vector.<String> = Vector.<String>([
			JointNames.HEAD,
			JointNames.NECK,
			JointNames.TORSO,
			JointNames.LEFT_SHOULDER,
			JointNames.LEFT_ELBOW,
			JointNames.LEFT_HAND,
			JointNames.RIGHT_SHOULDER,
			JointNames.RIGHT_ELBOW,
			JointNames.RIGHT_HAND,
			JointNames.LEFT_HIP,
			JointNames.LEFT_KNEE,
			JointNames.LEFT_FOOT,
			JointNames.RIGHT_HIP,
			JointNames.RIGHT_KNEE,
			JointNames.RIGHT_FOOT
		]);

	}
}
