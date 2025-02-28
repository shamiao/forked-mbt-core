// Copyright 2024 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Creates a new, empty vector.
pub fn Array::new[T]() -> Array[T] {
  []
}

/// Creates a new vector from an array.
pub fn Array::from_fixed_array[T](arr : FixedArray[T]) -> Array[T] {
  let len = arr.length()
  let arr2 = Array::make_uninit(len)
  for i = 0; i < len; i = i + 1 {
    arr2.buffer()[i] = arr[i]
  }
  arr2
}

pub fn Array::make[T](len : Int, elem : T) -> Array[T] {
  let arr = Array::make_uninit(len)
  for i = 0; i < len; i = i + 1 {
    arr.buffer()[i] = elem
  }
  arr
}

/// Returns the total number of elements the vector can hold without reallocating.
fn capacity[T](self : Array[T]) -> Int {
  self.buffer().0.length()
}

/// Reallocate the vector with a new capacity.
fn realloc[T](self : Array[T]) -> Unit {
  let old_cap = self.length()
  let new_cap = if old_cap == 0 { 8 } else { old_cap * 2 }
  self.resize_buffer(new_cap)
}

/// Retrieves the element at the specified index from the vector.
///
/// # Example
/// ```
/// let v = []
/// v.push(3)
/// println(v[0]) // 3
/// ```
/// @alert unsafe "Panic if index is out of bounds"
pub fn op_get[T](self : Array[T], index : Int) -> T {
  if index < 0 || index >= self.length() {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  self.buffer()[index]
}

/// Retrieves the element at the specified index from the vector, or `None` if index is out of bounds
///
/// # Example
/// ```
/// let v = []
/// v.push(3)
/// println(v.get(0)) // Some(3)
/// ```
pub fn get[T](self : Array[T], index : Int) -> T? {
  if index < 0 || index >= self.length() {
    return None
  }
  Some(self.buffer()[index])
}

/// Sets the value of the element at the specified index.
///
/// # Example
/// ```
/// let v = []
/// v.push(3)
/// println(v[0]) // 3
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn op_set[T](self : Array[T], index : Int, value : T) -> Unit {
  if index < 0 || index >= self.length() {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  self.buffer()[index] = value
}

/// Compares two vectors for equality.
pub fn op_equal[T : Eq](self : Array[T], other : Array[T]) -> Bool {
  if self.length() != other.length() {
    return false
  }
  for i = 0 {
    // CR: format issue
    if i >= self.length() {
      break true
    }
    if self[i] != other[i] {
      break false
    }
    continue i + 1
  }
}

pub fn op_add[T](self : Array[T], other : Array[T]) -> Array[T] {
  let result = Array::make_uninit(self.length() + other.length())
  for i = 0; i < self.length(); i = i + 1 {
    result.buffer()[i] = self.buffer()[i]
  }
  for i = 0; i < other.length(); i = i + 1 {
    result.buffer()[i + self.length()] = other.buffer()[i]
  }
  result
}

/// Removes the last element from a vector and returns it, or `None` if it is empty.
///
/// # Example
/// ```
/// let v = [1, 2, 3]
/// v.pop()
/// ```
pub fn pop[T](self : Array[T]) -> T? {
  if self.length() == 0 {
    None
  } else {
    let index = self.length() - 1
    let v = self.buffer()[index]
    self.set_length(index)
    Some(v)
  }
}

/// Removes the last element from a vector and returns it.
///
/// # Example
/// ```
/// let v = [1, 2, 3]
/// v.pop_exn() // 3
/// ```
/// @alert unsafe "Panic if the vector is empty."
pub fn pop_exn[T](self : Array[T]) -> T {
  if self.length() == 0 {
    abort("pop from an empty Array")
  }
  let index = self.length() - 1
  let v = self.buffer()[index]
  self.set_length(index)
  v
}

/// Adds an element to the end of the vector.
///
/// If the vector is at capacity, it will be reallocated.
///
/// # Example
/// ```
/// let v = []
/// v.push(3)
/// ```
pub fn push[T](self : Array[T], value : T) -> Unit {
  if self.length() == self.buffer().0.length() {
    self.realloc()
  }
  let length = self.length()
  self.buffer()[length] = value
  self.set_length(length + 1)
}

/// Removes the specified range from the vector and returns it.
///
/// This functions returns a vector range from `begin` to `end` `[begin, end)`
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let vv = v.drain(1, 2) // vv = [4], v = [3, 5]
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn drain[T](self : Array[T], begin : Int, end : Int) -> Array[T] {
  if begin < 0 || begin >= self.length() || end < 0 || end > self.length() || begin >
  end {
    let len = self.length()
    abort(
      "index out of bounds: the len is \(len) but the index is (\(begin), \(end))",
    )
  }
  let num = end - begin
  let v = Array::make_uninit(num)
  for i = begin; i < end; i = i + 1 {
    v.buffer()[i - begin] = self.buffer()[i]
  }
  for i = end; i < self.length(); i = i + 1 {
    self.buffer()[i - num] = self.buffer()[i]
  }
  self.set_length(self.length() - num)
  v
}

/// Appends all the elements of other vector into self
///
/// # Example
/// ```
/// let v1 = [3, 4, 5]
/// let v2 = [6, 7, 8]
/// v1.append(v2)
/// ```
/// TODO: could be made more efficient
pub fn append[T](self : Array[T], other : Array[T]) -> Unit {
  for i = 0; i < other.length(); i = i + 1 {
    self.push(other[i])
  }
}

/// Iterates over the elements of the vector.
///
/// # Example
/// ```
/// let v = Array::with_capacity(3)
/// v.push(3)
/// v.push(4)
/// v.push(5)
/// let mut sum = 0
/// v.iter(fn (x) {sum = sum + x})
/// ```
pub fn iter[T](self : Array[T], f : (T) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(self[i])
  }
}

pub fn iter_rev[T](self : Array[T], f : (T) -> Unit) -> Unit {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

/// Iterates over the elements of the vector with index.
///
/// # Example
/// ```
/// let v = Array::with_capacity(3)
/// v.push(3)
/// v.push(4)
/// v.push(5)
/// let mut sum = 0
/// v.iteri(fn (i, x) {sum = sum + x + i})
/// ```
pub fn iteri[T](self : Array[T], f : (Int, T) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(i, self[i])
  }
}

pub fn iter_revi[T](self : Array[T], f : (Int, T) -> Unit) -> Unit {
  let len = self.length()
  for i = 0; i < len; i = i + 1 {
    f(i, self[len - i - 1])
  }
}

/// Clears the vector, removing all values.
///
/// This method has no effect on the allocated capacity of the vector, only setting the length to 0.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.clear()
/// ```
pub fn clear[T](self : Array[T]) -> Unit {
  self.set_length(0)
}

/// Maps a function over the elements of the vector.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.map(fn (x) {x + 1})
/// ```
pub fn map[T, U](self : Array[T], f : (T) -> U) -> Array[U] {
  if self.length() == 0 {
    return []
  }
  let arr = Array::make_uninit(self.length())
  for i = 0; i < self.length(); i = i + 1 {
    arr.buffer()[i] = f(self.buffer()[i])
  }
  arr
}

/// Maps a function over the elements of the vector in place.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.map_inplace(fn (x) {x + 1})
/// ```
pub fn map_inplace[T](self : Array[T], f : (T) -> T) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    self.buffer()[i] = f(self.buffer()[i])
  }
}

/// Maps a function over the elements of the vector with index.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.mapi(fn (i, x) {x + i})
/// ```
pub fn mapi[T, U](self : Array[T], f : (Int, T) -> U) -> Array[U] {
  if self.length() == 0 {
    return []
  }
  let arr = Array::make_uninit(self.length())
  for i = 0; i < self.length(); i = i + 1 {
    arr.buffer()[i] = f(i, self.buffer()[i])
  }
  arr
}

/// Maps a function over the elements of the vector with index in place.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.mapi_inplace(fn (i, x) {x + i})
/// ```
pub fn mapi_inplace[T](self : Array[T], f : (Int, T) -> T) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    self[i] = f(i, self[i])
  }
}

/// Filters the array with a predicate function.
///
/// # Example
/// ```
/// let arr = [1, 2, 3, 4, 5, 6]
/// arr.filter(fn (x) { x % 2 == 0 }) // [2, 4, 6]
/// ```
pub fn filter[T](self : Array[T], f : (T) -> Bool) -> Array[T] {
  let arr = []
  self.iter(fn(e) { if f(e) { arr.push(e) } })
  arr
}

/// Test if the vector is empty.
///
/// # Example
/// ```
/// let v = []
/// v.is_empty()
/// ```
pub fn is_empty[T](self : Array[T]) -> Bool {
  self.length() == 0
}

/// Test if the vector is sorted.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.is_sorted() // true
/// ```
pub fn is_sorted[T : Compare](self : Array[T]) -> Bool {
  for i = 1 {
    if i >= self.length() {
      break true
    }
    if self[i - 1] > self[i] {
      break false
    }
    continue i + 1
  }
}

/// Reverses the order of elements in the slice, in place.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.reverse()
/// ```
pub fn reverse[T](self : Array[T]) -> Unit {
  for i = 0; i < self.length() / 2; i = i + 1 {
    let temp = self.buffer()[i]
    self.buffer()[i] = self.buffer()[self.length() - i - 1]
    self.buffer()[self.length() - i - 1] = temp
  }
}

/// Split the vector into two at the given index.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let (v1, v2) = v.split_at(1)
/// ```
/// TODO: perf could be optimized
/// @alert unsafe "Panic if index is out of bounds."
pub fn split_at[T](self : Array[T], index : Int) -> (Array[T], Array[T]) {
  if index < 0 || index >= self.length() {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  let v1 = Array::make_uninit(index)
  let v2 = Array::make_uninit(self.length() - index)
  for i = 0; i < index; i = i + 1 {
    v1[i] = self.buffer()[i]
  }
  for i = index; i < self.length(); i = i + 1 {
    v2[i - index] = self.buffer()[i]
  }
  (v1, v2)
}

/// Checks if the vector contains an element.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.contains(3)
/// ```
pub fn contains[T : Eq](self : Array[T], value : T) -> Bool {
  for i = 0; i < self.length(); i = i + 1 {
    if self.buffer()[i] == value {
      break true
    }
  } else {
    false
  }
}

/// Check if the vector starts with a given prefix.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.starts_with([3, 4])
/// ```
pub fn starts_with[T : Eq](self : Array[T], prefix : Array[T]) -> Bool {
  if prefix.length() > self.length() {
    return false
  }
  for i = 0; i < prefix.length(); i = i + 1 {
    if self.buffer()[i] != prefix.buffer()[i] {
      break false
    }
  } else {
    true
  }
}

/// Check if the vector ends with a given suffix.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.ends_with([5])
/// ```
pub fn ends_with[T : Eq](self : Array[T], suffix : Array[T]) -> Bool {
  if suffix.length() > self.length() {
    return false
  }
  for i = 0; i < suffix.length(); i = i + 1 {
    if self.buffer()[self.length() - suffix.length() + i] != suffix.buffer()[i] {
      break false
    }
  } else {
    true
  }
}

/// Strip a prefix from the vector.
///
/// If the vector starts with the prefix, return the vector after the prefix, otherwise return None.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.strip_prefix([3]) // Some([4, 5])
/// ```
pub fn strip_prefix[T : Eq](self : Array[T], prefix : Array[T]) -> Array[T]? {
  if self.starts_with(prefix) {
    let v = Array::make_uninit(self.length() - prefix.length())
    for i = prefix.length(); i < self.length(); i = i + 1 {
      v.buffer()[i - prefix.length()] = self.buffer()[i]
    }
    Some(v)
  } else {
    None
  }
}

/// Strip a suffix from the vector.
///
/// If the vector ends with the suffix, return the vector before the suffix, otherwise return None.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.strip_suffix([5]) // Some([3, 4])
/// ```
pub fn strip_suffix[T : Eq](self : Array[T], suffix : Array[T]) -> Array[T]? {
  if self.ends_with(suffix) {
    let v = Array::make_uninit(self.length() - suffix.length())
    let len = self.length() - suffix.length()
    for i = 0; i < len; i = i + 1 {
      v.buffer()[i] = self.buffer()[i]
    }
    Some(v)
  } else {
    None
  }
}

/// Search the vector index for a given element.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.search(3)
/// ```
pub fn search[T : Eq](self : Array[T], value : T) -> Int? {
  for i = 0; i < self.length(); i = i + 1 {
    if self.buffer()[i] == value {
      break Some(i)
    }
  } else {
    None
  }
}

/// Swap two elements in the vector.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.swap(1, 2)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn swap[T](self : Array[T], i : Int, j : Int) -> Unit {
  if i >= self.length() || j >= self.length() || i < 0 || j < 0 {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is (\(i), \(j))",
    )
  }
  let temp = self.buffer()[i]
  self.buffer()[i] = self.buffer()[j]
  self.buffer()[j] = temp
}

/// Remove an element from the vector at a given index.
///
/// Removes and returns the element at position index within the vector, shifting all elements after it to the left.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.remove(1)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn remove[T](self : Array[T], index : Int) -> T {
  if index < 0 || index >= self.length() {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  let value = self.buffer()[index]
  for i = index; i < self.length() - 1; i = i + 1 {
    self.buffer()[i] = self.buffer()[i + 1]
  }
  self.set_length(self.length() - 1)
  value
}

/// Retains only the elements specified by the predicate.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.retain(fn(x) { x > 3 })
/// ```
/// TODO: perf could be improved
pub fn retain[T](self : Array[T], f : (T) -> Bool) -> Unit {
  let mut i = 0
  while i < self.length() {
    if f(self.buffer()[i]).not() {
      self.remove(i) |> ignore
    } else {
      i = i + 1
    }
  }
}

/// Resize the vector to a new length with a default value.
///
/// # Example
/// ```
/// [3, 4, 5].resize(1)
/// ```
/// @alert unsafe "Panic if new length is negative."
pub fn resize[T](self : Array[T], new_len : Int, f : T) -> Unit {
  if new_len < 0 {
    abort("negative new length")
  }
  if new_len < self.length() {
    self.set_length(new_len)
  } else {
    for i = self.length(); i < new_len; i = i + 1 {
      self.push(f)
    }
  }
}

/// Inserts an element at a given index within the vector.
///
/// # Example
/// ```
/// [3, 4, 5].insert(1, 6)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn insert[T](self : Array[T], index : Int, value : T) -> Unit {
  if index < 0 || index > self.length() {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  if self.length() == self.buffer().0.length() {
    self.realloc()
  }
  for i = self.length(); i > index; i = i - 1 {
    self.buffer()[i] = self.buffer()[i - 1]
  }
  let length = self.length()
  self.buffer()[index] = value
  self.set_length(length + 1)
}

/// Flattens a vector of vectors into a vector.
///
/// # Example
/// ```
/// [[3, 4], [5, 6]].flatten()
/// ```
pub fn flatten[T](self : Array[Array[T]]) -> Array[T] {
  let v = []
  for i = 0; i < self.length(); i = i + 1 {
    v.append(self[i])
  }
  v
}

/// Create a vector by repeat a given vector for a given times.
///
/// # Example
/// ```
/// [3, 4].repeat(2)
/// ```
pub fn repeat[T](self : Array[T], times : Int) -> Array[T] {
  let v = Array::with_capacity(self.length() * times)
  for i = 0; i < times; i = i + 1 {
    v.append(self)
  }
  v
}

/// Flattens a vector of vectors with a given separator.
///
/// # Example
/// ```
/// [[3, 4], [5, 6]].join(0)
/// ```
pub fn join[T](self : Array[Array[T]], sep : T) -> Array[T] {
  let v = []
  for i = 0; i < self.length(); i = i + 1 {
    v.append(self[i])
    if i < self.length() - 1 {
      v.push(sep)
    }
  }
  v
}

/// Fold out values from an array according to certain rules.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_left(~init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
pub fn fold_left[T, U](self : Array[T], f : (U, T) -> U, ~init : U) -> U {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

/// Fold out values from an array according to certain rules in reversed turn.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_right(~init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
pub fn fold_right[T, U](self : Array[T], f : (U, T) -> U, ~init : U) -> U {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(acc, self[i])
  } else {
    acc
  }
}

/// Fold out values from an array according to certain rules with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_lefti(~init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
pub fn fold_lefti[T, U](self : Array[T], f : (Int, U, T) -> U, ~init : U) -> U {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(i, acc, self[i])
  } else {
    acc
  }
}

/// Fold out values from an array according to certain rules in reversed turn with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_righti(~init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
pub fn fold_righti[T, U](self : Array[T], f : (Int, U, T) -> U, ~init : U) -> U {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(self.length() - i - 1, acc, self[i])
  } else {
    acc
  }
}

/// Removes consecutive repeated elements in the vector according to the Eq trait.
///
/// # Example
/// ```
/// let v = [3, 4, 4, 5, 5, 5]
/// v.dedup() // v = [3, 4, 5]
/// ```
pub fn dedup[T : Eq](self : Array[T]) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    let mut j = i + 1
    while j < self.length() {
      if self[i] == self[j] {
        self.remove(j) |> ignore
      } else {
        j = j + 1
      }
    }
  }
}

/// Extract elements from the vector according to the given function.
///
/// This function will remove the elements from the original vector and return a new vector.
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let vv = v.extract_if(fn(x) { x > 3 }) // vv = [4, 5], v = [3]
/// ```
pub fn extract_if[T](self : Array[T], f : (T) -> Bool) -> Array[T] {
  let v = []
  let indices = []
  for i = 0; i < self.length(); i = i + 1 {
    if f(self[i]) {
      v.push(self[i])
      indices.push(i)
    }
  }
  for i = 0; i < indices.length(); i = i + 1 {
    self.remove(indices[i] - i) |> ignore
  }
  v
}

/// Group the elements of the vector into sized chunks.
///
/// If the elements of the vector cannot be divided into equal-sized chunks, the last chunk will be smaller.
///
/// # Example
/// ```
/// let v = [1, 2, 3, 4, 5, 6, 7, 8, 9]
/// let chunks = v.chunks(3) // chunks = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
/// ```
pub fn chunks[T](self : Array[T], size : Int) -> Array[Array[T]] {
  let chunks = []
  let mut i = 0
  while i < self.length() {
    let chunk = Array::with_capacity(size)
    for j = 0; j < size && i < self.length(); j = j + 1 {
      chunk.push(self[i])
      i = i + 1
    }
    chunks.push(chunk)
  }
  chunks
}

/// Group the elements of the vector into chunks based on a predicate.
///
/// # Example
/// ```
/// let v = [1, 1, 2, 3, 2, 3, 2, 3, 4]
/// let chunks = v.chunk_by(fn(x, y) { x <= y })
/// // chunks = [[1, 1, 2, 3], [2, 3], [2, 3], [4]]
/// ```
pub fn chunk_by[T](self : Array[T], pred : (T, T) -> Bool) -> Array[Array[T]] {
  let chunks = []
  let mut i = 0
  while i < self.length() {
    let chunk = []
    chunk.push(self[i])
    i = i + 1
    while i < self.length() && pred(self[i - 1], self[i]) {
      chunk.push(self[i])
      i = i + 1
    }
    chunks.push(chunk)
  }
  chunks
}

/// Split the vector into chunks based on a predicate.
///
/// # Example
/// ```
/// let v = [1, 0, 2, 0, 3, 0, 4]
/// let chunks = v.split(fn(x) { x == 0 })
/// ```
pub fn split[T](self : Array[T], pred : (T) -> Bool) -> Array[Array[T]] {
  let chunks = []
  let mut i = 0
  while i < self.length() {
    let chunk = []
    while i < self.length() && pred(self[i]).not() {
      chunk.push(self[i])
      i = i + 1
    }
    chunks.push(chunk)
    i = i + 1
  }
  chunks
}

/// Reserves capacity to ensure that it can hold at least the number of elements
/// specified by the `capacity` argument.
///
/// # Example
///
/// ```
/// let v = [1]
/// v.reserve_capacity(10)
/// println(v.capacity()) // 10
/// ```
pub fn reserve_capacity[T](self : Array[T], capacity : Int) -> Unit {
  if self.capacity() >= capacity {
    return
  }
  self.resize_buffer(capacity)
}

/// Shrinks the capacity of the vector as much as possible.
///
/// # Example
///
/// ```
/// let v = Array::with_capacity(10)
/// v.push(1)
/// v.push(2)
/// v.push(3)
/// println(v.capacity()) // >= 10
/// v.shrink_to_fit()
/// println(v.capacity()) // >= 3
/// ```
pub fn shrink_to_fit[T](self : Array[T]) -> Unit {
  if self.capacity() <= self.length() {
    return
  }
  self.resize_buffer(self.length())
}

/// Converts the vector to a string.
pub fn to_string[T : Show](self : Array[T]) -> String {
  if self.length() == 0 {
    return "[]"
  }
  let first = self.buffer()[0]
  // CR: format issues
  for i = 1, init = "[\(first)" {
    if i >= self.length() {
      break "\(init)]"
    }
    let cur = self.buffer()[i]
    continue i + 1, "\(init), \(cur)"
  }
}
