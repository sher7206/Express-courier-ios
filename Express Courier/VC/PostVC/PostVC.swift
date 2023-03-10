
//  PostVC.swift
//  Express Courier
//  Created by apple on 05/01/23.


import UIKit


enum PushNotification: String{
    case id = "id"
    case type = "type"
}

enum MailStatus{
    case new
    case accepted
    case active
    case completed
    case canceled
    case available
}

class PostVC: UIViewController {

    @IBOutlet weak var emptyStack: UIStackView!
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(TaxiFilterTVC.nib(), forCellReuseIdentifier: TaxiFilterTVC.identifier)
            tableView.register(PostInsideTVC.nib(), forCellReuseIdentifier: PostInsideTVC.identifier)
            tableView.separatorStyle = .none
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
            if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 } else {}
        }
    }
    
    var getAllDates: [GetPostRespnseData] = []
    var refreshControl = UIRefreshControl()

    let headerTexts = ["pochta1".localized, "pochta2".localized, "pochta3".localized, "pochta4".localized, "pochta5".localized, "pochta6".localized]
    
    var selectIndexCVC: Int = 0
    var isNew: Bool = true
    
    var orderPage = 1
    var newOrderPage = 1
    var acceptedPage = 1
    var activePage = 1
    var completedPage = 1
    var canceledPage = 1
    var availablePage = 1
    var pageType: MailStatus = .available
    var newStatus = "&status=new"
    var acceptedStatus = "&status=accepted"
    var activeStatus = "&status=active"
    var completedStatus = "&status=completed"
    var canceledStatus = "&status=canceled"
    var availableStatus = "/available"
    var totalItems: Int = 0
    var fromRegionId: Int?
    var fromDistrictId: Int?
    var toRegionId: Int?
    var toDistrictId: Int?
    var fromRegionText: String = "region4".localized
    var toRegionText: String = "region4".localized
    var isReplacement: Bool = true
    var isLeftRegion: Bool = true
    var downScroll: Bool = false

    let v = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        CheckUpdate.shared.showUpdate(withConfirmation: false, viewController: self)
        setupNavigation()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
        navigationItem.title = "tab1".localized
        setUpScretchView()
        getApiResponse(page: 1, fromRegionId: nil, fromDistrictId: nil, toRegionId: nil, toDistrictId: nil, status: "", available: "/available")
        makeCollectionView()
        NotificationCenter.default.addObserver(self, selector: #selector(pushNotification), name: NSNotification.Name(Keys.notificationName), object: nil)
    }
    
    @objc func pushNotification(_ notification: Notification){
        if let userInfo = notification.userInfo {
            if let id = userInfo[PushNotification.id.rawValue] as? String {
                if let type = userInfo[PushNotification.type.rawValue] as? String{
                    let idInt = Int(id) ?? 0
                    switch type{
                    case "news":
                        getApiforNews(id: idInt)
                    case "package":
                        let vc = ArrivedPostVC()
                        vc.id = idInt
                        vc.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(vc, animated: true)
                    case "packageList":
                        let vc = ListVC()
                        vc.itemId = idInt
                        navigationController?.pushViewController(vc, animated: true)
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func getApiforNews(id: Int){
        let servise = UserService()
        servise.getOneNewDataResponse(model: NewRequest(id: id)) { result in
            switch result{
            case.success(let content):
                guard let data = content.data else {return}
                let vc = AboutNewVC()
                vc.dates = data
                self.present(vc, animated: true, completion: nil)
            case.failure(let error):
                Alert.showAlert(forState: .error, message: error.localizedDescription, vibrationType: .error)
            }
        }
    }
    
    func getApiResponse(page: Int, fromRegionId: Int?, fromDistrictId: Int?, toRegionId: Int?,toDistrictId: Int?,status: String, available: String){
        self.emptyStack.isHidden = true
        let service = PostService()
        Loader.start()
        service.getPostResponse(model: PostRequest(page: page, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: status, available: available)) { [self] result in
            switch result{
            case .success(let content):
                Loader.stop()
                guard let dates = content.data else{return}
                guard let meta = content.meta?.total else{return}
                self.totalItems = meta
                getAllDates.append(contentsOf: dates)
                emptyStack.isHidden = !getAllDates.isEmpty
                self.tableView.reloadData()
            case .failure(let error):
                Loader.stop()
                Alert.showAlert(forState: .error, message: error.localizedDescription, vibrationType: .error)
            }
        }
    }
    @objc func refresh(send: UIRefreshControl) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }


    @IBAction func scanBtnPressed(_ sender: Any) {
        let vc = ScannerVC()
        vc.hidesBottomBarWhenPushed = true
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func listBtnPressed(_ sender: Any) {
        let vc = ListBranchVC()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

//MARK: - Table View Delegate
extension PostVC: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, ScannerVCDelegate {
    func isScannered(id: Int) {
        let vc = ArrivedPostVC()
        vc.id = id
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return getAllDates.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaxiFilterTVC", for: indexPath) as? TaxiFilterTVC else {return UITableViewCell()}
            cell.delegate = self
            cell.updateCell(from: fromRegionText, to: toRegionText, fromRegionId: nil, toRegionId: nil)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PostInsideTVC.identifier, for: indexPath) as? PostInsideTVC else {return UITableViewCell()}
            cell.updateCell(data: getAllDates[indexPath.row])
            if indexPath.row == 0{
                cell.headerDateLbl.isHidden = false
            }else{
                let first = getAllDates[indexPath.row-1].created_at
                let second = getAllDates[indexPath.row].created_at
                if first?.prefix(10) == second?.prefix(10){
                    cell.headerDateLbl.isHidden = true
                }else{
                    cell.headerDateLbl.isHidden = false
                }
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return v
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section != 0 {
            return 40
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        if pageType == .available{
            let vc = PostAgreemantVC()
            vc.modalPresentationStyle = .overFullScreen
            vc.delegate = self
            vc.id = getAllDates[indexPath.row].id ?? 0
            present(vc, animated: true, completion: nil)
        }else{
            let vc = ArrivedPostVC()
            vc.id = getAllDates[indexPath.row].id ?? 0
            vc.hidesBottomBarWhenPushed = true
            vc.delegate = self
            vc.orderType = pageType
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == getAllDates.count-1 {
            if self.totalItems > getAllDates.count {
                switch pageType{
                case .new:
                    newOrderPage += 1
                    takePageAnation(page: newOrderPage, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: newStatus, available: "")
                case .accepted:
                    acceptedPage += 1
                    takePageAnation(page: acceptedPage, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: acceptedStatus, available: "")
                case .active:
                    activePage += 1
                    takePageAnation(page: activePage, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: activeStatus, available: "")
                case .completed:
                    completedPage += 1
                    takePageAnation(page: completedPage, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: completedStatus, available: "")
                case .canceled:
                    canceledPage += 1
                    takePageAnation(page: canceledPage, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: canceledStatus, available: "")
                case .available:
                    availablePage += 1
                    takePageAnation(page: orderPage, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: "", available: availableStatus)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if downScroll {
                return UITableView.automaticDimension
            } else {
                return 0
            }
        } else {
            return UITableView.automaticDimension
        }
    }

    func takePageAnation(page: Int, fromRegionId: Int?, fromDistrictId: Int?, toRegionId: Int?,toDistrictId: Int?,status: String, available: String){
        Loader.start()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            Loader.stop()
            getApiResponse(page: page, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: status, available: available)
            tableView.reloadData()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let header = tableView.tableHeaderView as? SkretchableHeaderView else{
            return
        }
        header.crollViewDidScroll(scrollView: tableView)
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if translation.y > 0 {
            if !downScroll {
                self.tableView.beginUpdates()
                self.downScroll = true
                self.tableView.endUpdates()
            }
        }
    }
    
}


//MARK: - Collection View Delegate
extension PostVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return headerTexts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TaxiHeaderCVC", for: indexPath) as? TaxiHeaderCVC else {return UICollectionViewCell()}
        
        cell.bottomView.backgroundColor = .clear
        cell.titleLbl.textColor = UIColor(named: "black600")
        cell.titleLbl.font = .systemFont(ofSize: 15, weight: .regular)
        
        if selectIndexCVC == indexPath.row {
            cell.bottomView.backgroundColor = .black
            cell.titleLbl.textColor = .black
            cell.titleLbl.font = .systemFont(ofSize: 17, weight: .medium)
        } else {
            cell.bottomView.backgroundColor = .clear
            cell.titleLbl.textColor = UIColor(named: "black600")
            cell.titleLbl.font = .systemFont(ofSize: 17, weight: .regular)
        }
        
        cell.updateCell(title: headerTexts[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectIndexCVC = indexPath.row
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        collectionView.reloadData()
        getAllDates.removeAll()
        switch indexPath.row{
        case 0:
            pageType = .available
            availablePage = 1
            getApiResponse(page: availablePage, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: "", available: availableStatus)
        case 1:
            pageType = .new
            newOrderPage = 1
            getApiResponse(page: newOrderPage, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: newStatus, available: "")
        case 2:
            pageType = .accepted
            acceptedPage = 1
            getApiResponse(page: acceptedPage, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: acceptedStatus, available: "")
        case 3:
            pageType = .active
            activePage = 1
            getApiResponse(page: activePage, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: activeStatus, available: "")
        case 4:
            pageType = .completed
            completedPage = 1
            getApiResponse(page: completedPage, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: completedStatus, available: "")
        case 5:
            pageType = .canceled
            canceledPage = 1
            getApiResponse(page: canceledPage, fromRegionId: fromRegionId, fromDistrictId: fromDistrictId, toRegionId: toRegionId, toDistrictId: toDistrictId, status: canceledStatus, available: "")
        default:
            print("Smth")
        }
        tableView.reloadData()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.headerTexts[indexPath.row].widthOfStringg(usingFont: .systemFont(ofSize: 15)) + 25, height: 40)
    }
    
}

//MARK: REGIONS
extension PostVC: TaxiFilterTVCDelegate{
    
    func fromRegionTapped() {
        self.isLeftRegion = true
        let vc = RegionsVC()
        vc.vc = self
        present(vc, animated: true)
    }
    
    func toRegionTapped() {
        self.isLeftRegion = false
        let vc = RegionsVC()
        vc.vc = self
        present(vc, animated: true)
    }
    
    func fromCloseTapped() {
        
        if fromRegionId == nil || toDistrictId == nil {
            self.toRegionId = nil
            self.toDistrictId = nil
        }
        self.fromRegionId = nil
        self.toDistrictId = nil
        self.fromRegionText = "Viloyat, tuman"
        
        pageTypeReloadData(fromR: fromRegionId, fromD: fromDistrictId, toR: toRegionId, toD: toDistrictId)
    }
    
    func toCloseTapped() {
        
        if toRegionId == nil || toDistrictId == nil {
            self.fromRegionId = nil
            self.fromDistrictId = nil
        }
        self.toRegionId = nil
        self.toDistrictId = nil
        self.toRegionText = "Viloyat, tuman"
        pageTypeReloadData(fromR: fromRegionId, fromD: fromDistrictId, toR: toRegionId, toD: toDistrictId)
    }
    
    func replaceTapped() {
        let a = fromRegionText
        let b = toRegionText
        self.fromRegionText = b
        self.toRegionText = a
        
        if isReplacement{
            pageTypeReloadData(fromR: toRegionId, fromD: toDistrictId, toR: fromRegionId, toD: fromDistrictId)
        }else{
            pageTypeReloadData(fromR: fromRegionId, fromD: fromDistrictId, toR: toRegionId, toD: toDistrictId)
        }
        
        isReplacement = !isReplacement
    }
    
    func pageTypeReloadData(fromR: Int?, fromD: Int?, toR: Int?, toD: Int?){
        getAllDates.removeAll()
        switch pageType{
        case .new:
            newOrderPage = 1
            getApiResponse(page: newOrderPage, fromRegionId: fromR, fromDistrictId: fromD, toRegionId: toR, toDistrictId: toD, status: newStatus, available: "")
        case .accepted:
            acceptedPage = 1
            getApiResponse(page: acceptedPage, fromRegionId: fromR, fromDistrictId: fromD, toRegionId: toR, toDistrictId: toD, status: acceptedStatus, available: "")
        case .active:
            activePage = 1
            getApiResponse(page: activePage, fromRegionId: fromR, fromDistrictId: fromD, toRegionId: toR, toDistrictId: toD, status: activeStatus, available: "")
        case .completed:
            completedPage = 1
            getApiResponse(page: completedPage, fromRegionId: fromR, fromDistrictId: fromD, toRegionId: toR, toDistrictId: toD, status: completedStatus, available: "")
        case .canceled:
            canceledPage = 1
            getApiResponse(page: canceledPage, fromRegionId: fromR, fromDistrictId: fromD, toRegionId: toR, toDistrictId: toD, status: canceledStatus, available: "")
        case .available:
            availablePage = 1
            getApiResponse(page: availablePage, fromRegionId: fromR, fromDistrictId: fromD, toRegionId: toR, toDistrictId: toD, status: "", available: availableStatus)
        }
    }
    
}

//MARK: - Region Selected Delegate
extension PostVC: RegionSelectedVCDelegate, PostAgreemantVCDelegate,ArrivedPostVCDelegate{
    
    func cancelOrder() {
        dataUpdater()
    }
    
    func dataUpdater() {
        pageTypeReloadData(fromR: fromRegionId, fromD: fromDistrictId, toR: toRegionId, toD: toDistrictId)
    }
    
    func setLocatoin(region id: Int, regoin name: String, state: States, isToRegion: Bool) {
            if isLeftRegion {
                self.fromRegionText = name + ", " + state.name
                self.fromRegionId = id
                self.fromDistrictId = state.id
            } else {
                self.toRegionText = name + ", " + state.name
                self.toRegionId = id
                self.toDistrictId = state.id
            }
        pageTypeReloadData(fromR: fromRegionId, fromD: fromDistrictId, toR: toRegionId, toD: toDistrictId)
    }
    
}

extension PostVC{
    func makeCollectionView(){
        v.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 40)
        v.backgroundColor = UIColor(named: "primary900")
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        self.view.addSubview(collectionView)
        collectionView.delegate   = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "TaxiHeaderCVC", bundle: nil), forCellWithReuseIdentifier: "TaxiHeaderCVC")
        v.addSubview(collectionView)
        collectionView.backgroundColor = UIColor(named: "primary900")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: v.topAnchor, constant: 0).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: 0).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 0).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: 0).isActive = true
        layout.collectionView?.showsHorizontalScrollIndicator = false
    }
    
    func setupNavigation(){
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "primary900")
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationItem.backButtonTitle = ""
    }
    
    func setUpScretchView(){
        let header = SkretchableHeaderView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 5))
        header.v.backgroundColor = UIColor(named: "primary900")
        tableView.tableHeaderView = header
        self.view.backgroundColor = UIColor(named: "white300")
    }
    
}
