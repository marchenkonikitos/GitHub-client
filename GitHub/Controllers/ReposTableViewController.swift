//
//  ReposTableViewController.swift
//  GitHub test
//
//  Created by Nikita Marchenko on 01.03.2018.
//  Copyright © 2018 Nikita Marchenko. All rights reserved.
//

import UIKit
import PromiseKit
import Swinject
import CoreData

class ReposTableViewController: UITableViewController {
    
    @IBOutlet var userImage: UIImageView!
    
    private var repositoriesArray: [Repository] = []
    private let variable = DIContainer.container.resolve(Variables.self)!
    private let repositoriesService = DIContainer.container.resolve(RepositoryServices.self)!
    private let userServices = DIContainer.container.resolve(UserServices.self)!
    
    lazy var fetchedResultsController: NSFetchedResultsController<Repository> = {
        let request = NSFetchRequest<Repository>(entityName: "Repository")
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let departmentSort = NSSortDescriptor(key: "id", ascending: false)
        request.sortDescriptors = [departmentSort]
        
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
    
        do {
            try frc.performFetch()
        } catch {
            debugPrint(error.localizedDescription)
        }
        return frc
    }()
    
    lazy var refreshController = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(self.refreshData(_:)), for: .valueChanged)
        rc.tintColor = .gray
        rc.attributedTitle = NSAttributedString(string: "Refreshing")
        self.tableView.addSubview(rc)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getData()
        changeUserImage()
        changeNumberOfRepos()
        createRefreshController()
    }
    
    //MARK: -Change datas in header
    func changeUserImage() {
        self.userImage.layer.masksToBounds = true
        self.userImage.layer.cornerRadius = self.userImage.frame.height / 2
        
        let imageData = userServices.getAvatar()
        
        if imageData != nil {
            self.userImage.image = UIImage(data: imageData! as Data)
        }
    }
    
    func changeNumberOfRepos() {
        self.title = "Repositories: \(fetchedResultsController.fetchedObjects?.count ?? 0)"
    }
    
    func createRefreshController() {
        let refreshController = UIRefreshControl()
        refreshController.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        refreshController.tintColor = .gray
        refreshController.attributedTitle = NSAttributedString(string: "Refreshing")
        tableView.addSubview(refreshController)
    }
    
    @objc
    func refreshData(_ refresher: UIRefreshControl) {
        getData()
        changeNumberOfRepos()
        refresher.endRefreshing()
    }
    
    @objc
    func imageTapped(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            self.navigationController?.title = UserDefaults.standard.value(forKey: "userName") as? String
        } else if gesture.state == .ended {
            changeNumberOfRepos()
        }
    }
    
    //MARK: -Get and save repositories
    func getData() {
        repositoriesService.getRepositories().done {
            self.changeNumberOfRepos()
            }.catch { error in
            let alert = UIAlertController(title: "Problem", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if let count = fetchedResultsController.sections?[section].numberOfObjects {
            return count
        }
        return 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reposCell", for: indexPath) as! RepositoryTableViewCell
        
        let repository = fetchedResultsController.object(at: indexPath)
        cell.initCell(repository: repository)
        
        return cell
    }
    
    var selectedRepository: Repository?
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedRepository = fetchedResultsController.object(at: indexPath)
        
        performSegue(withIdentifier: "goToIssues", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        (segue.destination as? IssueTableViewController)?.repository = selectedRepository!
    }
    
    @IBAction func imagePressed(_ sender: Any) {
        debugPrint("pressed")
    }
    
    
    @IBAction func logoutPressed(_ sender: Any) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let sb = UIStoryboard(name: "Main", bundle: nil)
        delegate.window?.rootViewController = sb.instantiateInitialViewController()
        
        userServices.logOut()
    }
}

extension ReposTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.moveRow(at: indexPath, to: newIndexPath)
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
