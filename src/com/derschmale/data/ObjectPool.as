package com.derschmale.data
{
	import flash.utils.Dictionary;

	public class ObjectPool
	{
		private var _type : Class;
		private var _pool : Vector.<Object>;
		private var _index : int;
		private var _size : int;
		private var _maxSize : int;
		private var _incrementSize : int;

		private static var _globalPools : Dictionary;

		public static function getGlobalPool(type : Class) : ObjectPool
		{
			_globalPools ||= new Dictionary();
			return _globalPools[type] = new ObjectPool(type);
		}

		public static function deleteGlobalPool(type : Class) : void
		{
			if (_globalPools[type]) {
				_globalPools[type].clear();
				delete _globalPools[type];
			}
		}

		public function ObjectPool(type : Class, maxSize : int = 100, incrementSize : int = 10)
		{
			_type = type;
			_maxSize = maxSize;
			_incrementSize = incrementSize;
			clear();
		}

		public function clear() : void
		{
			_pool = null;
			_index = _size = 0;
		}

		public function alloc() : Object
		{
			if (_index == _size) {
				_pool ||= new Vector.<Object>();
				if (_size == _maxSize) throw new Error("Number of pool items grew beyond the maximum allotted size!");
				_size += _incrementSize;
				if (_size > _maxSize)
					_size = _maxSize;

				for (var i : int = _index; i < _size; ++i) _pool[i] = new _type();
			}

			return _pool[_index++];
		}

		public function free(obj : Object) : void
		{
			if (_index < 0) throw new Error("Tried to free more objects than were alloced!");
			_pool[--_index] = obj;
		}
	}
}
