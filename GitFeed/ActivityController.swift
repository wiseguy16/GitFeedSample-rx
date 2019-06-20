

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
        
        // Using Native urlsession (needs Dispatch.main.async to process)
        //viewModel.fetchGitFeedEvents(repo: repo)
        
        // Using Alamofire urlsession
        //viewModel.fetchObjectsNative(repo: repo)
        //bindUI()
        
        // Using RX urlsession
        viewModel.fetchEventsRx(repo: repo)
        bindUI()
        
        // refresh()
        // bindUI()
    }
    
    @objc func refresh() {
        viewModel.fetchEventsRx(repo: repo)
    }
    
    func bindUI() {
        viewModel.publicEvents.bindTo(tableView.rx.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { (row, event, cell) in
            
            cell.textLabel?.text = event.name
            cell.detailTextLabel?.text = event.repo + ", " + event.action.replacingOccurrences(of: "Event", with: "").lowercased()
            cell.imageView?.kf.setImage(with: event.imageUrl, placeholder: UIImage(named: "blank-avatar"))
            }
            .addDisposableTo(bag)
    }
    

    // MARK: - This was old way if you didn't use bindings
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
    
    //MARK: - This is not needed because of use of bindings
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
