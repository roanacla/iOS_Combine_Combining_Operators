// Copyright (c) 2019 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "prepend(Output...)") {
  // 1
  let publisher = [3, 4].publisher
  
  // 2
  publisher
    .prepend(1, 2)//Use Prepend to add values before the publisher's own values.
    .prepend(-1,0)//The last prepend executes first! REMEMBER THIS
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

//——— Example of: prepend(Output...) ———
//-1
//0
//1
//2
//3
//4

example(of: "prepend(Sequence)") {
  // 1
  let publisher = [5, 6, 7].publisher
  
  // 2
  publisher
    .prepend([3, 4])
    .prepend(Set(1...2)) //Prepend can take values from any type that conformes SEQUENCE. it could be an array or a set.
    //REMEMBER that SET, the order is not garanteed
    .prepend(stride(from: 6, to: 11, by: 2))
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

//——— Example of: prepend(Sequence) ———
//6
//8
//10
//1
//2
//3
//4
//5
//6
//7


example(of: "prepend(Publisher)") {
  // 1
  let publisher1 = [3, 4].publisher
  let publisher2 = [1, 2].publisher
  
  // 2
  publisher1
    .prepend(publisher2) //execute publisher 2 first, after completes execute publihser 1
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

//——— Example of: prepend(Publisher) ———
//1
//2
//3
//4

example(of: "prepend(Publisher) #2") {
  // 1
  let publisher1 = [3, 4].publisher
  let publisher2 = PassthroughSubject<Int, Never>()
  
  // 2
  publisher1
    .prepend(publisher2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

  // 3
  publisher2.send(1)
  publisher2.send(2)
    publisher2.send(completion: .finished)//This line must execute if you want the values from publisher 1 to show up.
}

//——— Example of: prepend(Publisher) #2 ———
//1
//2
//3
//4

example(of: "append(Output...)") {
  // 1
  let publisher = [1].publisher //1 is published first

  // 2
  publisher
    .append(2, 3) //2,3 is published second
    .append(4) //4, is published last because APPEND waits for the upstream to complete.
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

//——— Example of: append(Output...) ———
//1
//2
//3
//4

example(of: "append(Output...) #2") {
  // 1
  let publisher = PassthroughSubject<Int, Never>()

  publisher
    .append(3, 4) //This APPEND wont upstream until the passtrhoughSubject publishe finish upstreaming. (.finished)
    .append(5)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  // 2
  publisher.send(1)
  publisher.send(2)
  publisher.send(completion: .finished)
}

//——— Example of: append(Output...) #2 ———
//1
//2
//3
//4
//5


example(of: "append(Sequence)") {
  // 1
  let publisher = [1, 2, 3].publisher
    
  publisher
    .append([4, 5]) // 2
    .append(Set([6, 7])) // 3 append(sequence:) support any Sequence-confirming object
    .append(stride(from: 8, to: 11, by: 2)) // 4
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

//——— Example of: append(Sequence) ———
//1
//2
//3
//4
//5
//6
//7
//8
//10

example(of: "append(Publisher)") {
  // 1
  let publisher1 = [1, 2].publisher
  let publisher2 = [3, 4].publisher
  
  // 2
  publisher1
    .append(publisher2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}
//——— Example of: append(Publisher) ———
//1
//2
//3
//4

example(of: "switchToLatest") {
  // 1
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<Int, Never>()
    let publisher3 = PassthroughSubject<Int, Never>()
    
    // 2 This is how you create a publisher of publishers
    let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()
    
    // 3
    publishers
        .switchToLatest()//Every time you send a new publisher, it switches to the new one and cancel the previous subscription.
                         //This garantee that only one publisher will emit values and cancel any previous subscriptions
        .sink(receiveCompletion: { _ in print("Completed!") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    // 4
    publishers.send(publisher1)
    publisher1.send(1)
    publisher1.send(2)
    
    // 5
    publishers.send(publisher2)
    publisher1.send(3) // this value will not be published because .switchToLatest() cancels publisher1
    publisher2.send(4)
    publisher2.send(5)
    
    // 6
    publishers.send(publisher3)
    publisher2.send(6) // this value will not be published because .switchToLatest() cancels publisher2
    publisher3.send(7)
    publisher3.send(8)
    publisher3.send(9)
    
    // 7
    publisher3.send(completion: .finished)
    publishers.send(completion: .finished)
}
//If you’re not sure why this is useful in a real-life app, consider the following scenario: Your user taps a button that triggers a network request. Immediately afterward, the user taps the button again, which triggers a second network request. But how do you get rid of the pending request, and only use the latest request? switchToLatest to the rescue!
//——— Example of: switchToLatest ———
//1
//2
//4
//5
//7
//8
//9
//Completed!

example(of: "switchToLatest - Network Request") {
  let url = URL(string: "https://source.unsplash.com/random")!

  // 1
  func getImage() -> AnyPublisher<UIImage?, Never> {
      return URLSession.shared
                       .dataTaskPublisher(for: url) //Combine extension for foundation
                       .map { data, _ in UIImage(data: data) }
                       .print("image")
                       .replaceError(with: nil)
                       .eraseToAnyPublisher()
  }

  // 2
  let taps = PassthroughSubject<Void, Never>()
  taps
      .map { _ in getImage() } // 3
      .switchToLatest() // 4 This garantee that only one publisher will emit values and cancel any previous subscriptions
      .sink(receiveValue: { _ in })
      .store(in: &subscriptions)

    // 5
    taps.send()

    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      taps.send()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) { //because this value is send in 0.1 seconds, it dones't give enought time the previous publisher to complete.
        //Therefore, you only receive two values
      taps.send()
    }
  }
//——— Example of: switchToLatest - Network Request ———
//image: receive subscription: (DataTaskPublisher)
//image: request unlimited
//image: receive value: (Optional(<UIImage:0x600002008750 anonymous {1080, 721}>))
//image: receive finished
//image: receive subscription: (DataTaskPublisher)
//image: request unlimited
//image: receive value: (Optional(<UIImage:0x600002008870 anonymous {1080, 721}>))
//image: receive finished
//image: receive subscription: (DataTaskPublisher)
//image: request unlimited
//image: receive value: (Optional(<UIImage:0x60000201c7e0 anonymous {1080, 1620}>))
//image: receive finished

example(of: "merge(with:)") {
  // 1
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<Int, Never>()

  // 2
  publisher1
    .merge(with: publisher2)
    .sink(receiveCompletion: { _ in print("Completed") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)

  // 3
  publisher1.send(1)
  publisher1.send(2)

  publisher2.send(3)

  publisher1.send(4)

  publisher2.send(5)

  // 4
  publisher1.send(completion: .finished)
  publisher2.send(completion: .finished)//Both publisher have to complete so the merge receiveCompletion-closure is executed.
}

//——— Example of: merge(with:) ———
//1
//2
//3
//4
//5

example(of: "combineLatest") {
  // 1
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<String, Never>()

  // 2
  publisher1
    .combineLatest(publisher2)//“Combine the latest emissions of publisher2 with publisher1. You may combine up to four different publishers using different overloads of combineLatest.
    .sink(receiveCompletion: { _ in print("Completed") },
          receiveValue: { print("P1: \($0), P2: \($1)") })
    .store(in: &subscriptions)

  // 3
  publisher1.send(1)
  publisher1.send(2)
  
  publisher2.send("a")
  publisher2.send("b")
  
  publisher1.send(3)
  
  publisher2.send("c")

  // 4
  publisher1.send(completion: .finished)
  publisher2.send(completion: .finished)
}
//CombineLatest only combines once every publisher emits at least one value. Here, that condition is true only after "a" emits, at which point the latest emitted value from publisher1 is 2. That’s why the first emission is (2, "a").
//——— Example of: combineLatest ———
//P1: 2, P2: a
//P1: 2, P2: b
//P1: 3, P2: b
//P1: 3, P2: c
//Completed

example(of: "zip") {
  // 1
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<String, Never>()

  // 2
  publisher1
      .zip(publisher2)
      .sink(receiveCompletion: { _ in print("Completed") },
            receiveValue: { print("P1: \($0), P2: \($1)") })
      .store(in: &subscriptions)

  // 3
  publisher1.send(1)
  publisher1.send(2)
  publisher2.send("a")
  publisher2.send("b")
  publisher1.send(3)
  publisher2.send("c")
  publisher2.send("d")

  // 4
  publisher1.send(completion: .finished)
  publisher2.send(completion: .finished)
}
//Notice how each emitted value "waits" for the other zipped publisher to emit an value. 1 waits for the first emission from the second publisher, so you get (1, "a"). Likewise, 2 waits for the next emission from the second publisher, so you get (2, "b"). The last emitted value from the second publisher, "d", is ignored since there is no corresponding emission from the first publisher to pair with.”
//——— Example of: zip ———
// P1: 1, P2: a
// P1: 2, P2: b
// P1: 3, P2: c
// Completed
