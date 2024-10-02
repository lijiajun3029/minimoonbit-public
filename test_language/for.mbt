fn sum1(array : Array[Int]) -> Int {
  let mut sum = 0
  for i = 0; i < array.length(); i = i + 1 {
    sum += array[i]
  }
  sum
}

fn sum2(array : Array[Int]) -> Int {
  let mut sum = 0
  for i in array {
    sum += i
  }
  sum
}

fn main {
  let array : Array[Int] = [1,2,3,1024]
  println(sum1(array))
  println(sum2(array))
}