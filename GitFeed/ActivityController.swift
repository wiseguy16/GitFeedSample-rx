

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

class ActivityController: UITableViewController {
    
    let repo = "ReactiveX/RxSwift"
    
    fileprivate let events = Variable<[Event]>([])
    fileprivate let bag = DisposeBag()
    
    let viewModel = ACViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = repo
        tableView.delegate = nil
        tableView.dataSource = nil
        
        self.refreshControl = UIRefreshControl()
        let refreshControl = self.refreshControl!
        
        refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        refreshControl.tintColor = UIColor.darkGray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        //viewModel.fetchGitFeedEvents(repo: repo)
        viewModel.fetchObjectsNative(repo: repo)
        bindUI()
        
        // refresh()
    }
    
    @objc func refresh() {
        fetchEvents(repo: repo)
    }
    
    func bindUI() {
        viewModel.publicEvents.bindTo(tableView.rx.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { (row, event, cell) in
            
            cell.textLabel?.text = event.name
            cell.detailTextLabel?.text = event.repo + ", " + event.action.replacingOccurrences(of: "Event", with: "").lowercased()
            cell.imageView?.kf.setImage(with: event.imageUrl, placeholder: UIImage(named: "blank-avatar"))
            }
            .addDisposableTo(bag)
    }
    
    
    
    func fetchEvents(repo: String) {
        
        let response = Observable.from([repo])
            .map { urlString -> URL in
                return URL(string: "https://api.github.com/repos/\(urlString)/events")!
            }
            .map { url -> URLRequest in
                return URLRequest(url: url)
            }
            .flatMap { request -> Observable<(HTTPURLResponse, Data)> in
                return URLSession.shared.rx.response(request: (request))
            }
            .shareReplay(1)
        
        response
            .filter { response, dontCareAboutThisData -> Bool in
                print("\(dontCareAboutThisData)")
                return 200..<300 ~= response.statusCode
            }
            .map { dontCareAboutThisResponse, data -> [[String: Any]] in
                print("\(dontCareAboutThisResponse)")
                guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                    let result = jsonObject as? [[String: Any]] else {
                        return []
                }
                return result
            }
            .filter { objects in
                return objects.count > 0
            }
            .map { objects in
                return objects.flatMap {
                    print("\($0)")
                    return Event(dictionary: $0)
                    
                }
            }
            .subscribe(onNext: { [weak self] newEvents in
                self?.processEvents(newEvents)
            })
            
            .addDisposableTo(bag)
        
        
    }
    
    func processEvents(_ newEvents: [Event]) {
        var updatedEvents = newEvents + events.value
        if updatedEvents.count > 50 {
            updatedEvents = Array<Event>(updatedEvents.prefix(upTo: 50))
        }
        
        events.value = updatedEvents
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            self?.refreshControl?.endRefreshing()
        }
    }
    
//    // MARK: - Table Data Source
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return events.value.count
//    }
//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let event = events.value[indexPath.row]
//        
//        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
//        cell.textLabel?.text = event.name
//        cell.detailTextLabel?.text = event.repo + ", " + event.action.replacingOccurrences(of: "Event", with: "").lowercased()
//        cell.imageView?.kf.setImage(with: event.imageUrl, placeholder: UIImage(named: "blank-avatar"))
//        return cell
//    }
}
