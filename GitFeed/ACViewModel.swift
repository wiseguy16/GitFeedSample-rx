//
//  ACViewModel.swift
//  GitFeed
//
//  Created by Greg Weiss on 6/19/19.
//  Copyright © 2019 Underplot ltd. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

class ACViewModel {
    
    fileprivate let events = Variable<[Event]>([])
    
    public var publicEvents: Observable<[Event]> {
        return events.asObservable()
    }
    
    fileprivate let bag = DisposeBag()
    
    func fetchGitFeedEvents(repo: String) {
        let url = URL(string: "https://api.github.com/repos/\(repo)/events")!
        Alamofire.request(url)
            .validate()
            .responseJSON() { [weak self] response in
                if let json = response.result.value as? [[String: Any]] {
                    let newEvents = json.flatMap { Event(dictionary: $0) }
                    self?.processEvents(newEvents)
                }
        }
    }
    
    func processEvents(_ newEvents: [Event]) {
        var updatedEvents = newEvents + events.value
        if updatedEvents.count > 50 {
            updatedEvents = Array<Event>(updatedEvents.prefix(upTo: 50))
        }
        events.value = updatedEvents
    }
    
    func fetchObjectsNative(repo: String) {
        let url = URL(string: "https://api.github.com/repos/\(repo)/events")!
        let session = URLSession.shared
        
        let task = session.dataTask(with: url) { [weak self] (data, response, error) in
            
            if error != nil || data == nil {
                print("Client error!")
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Server error!")
                return
            }
            
            guard let mime = response.mimeType, mime == "application/json" else {
                print("Wrong MIME type!")
                return
            }
            
            guard let safeData = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: safeData, options: []) as? [[String: Any]]  {
                    let newEvents = json.flatMap { Event(dictionary: $0) }
                    DispatchQueue.main.async {
                        self?.processEvents(newEvents)
                        print(json)
                    }
                }
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
}

