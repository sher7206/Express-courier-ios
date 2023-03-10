//
//  UserService.swift
//  Express Courier
//
//  Created by Sherzod on 13/01/23.
//

import Alamofire

struct UserService: BaseService {
    
    typealias Convertible = UserRouter
    
    func getMe(completion: @escaping Completion<GetMeResponse>) {
        request(.getMe, completion: completion)
    }
    
    func getTransactions(model: GetTransactionsRequest, completion: @escaping Completion<GetTransactionsResponse>) {
        request(.getTransactions(model: model), completion: completion)
    }
    
    func getNotifications(model: GetNotificationsRequest, completion: @escaping Completion<GetNotificationsResponse>) {
        request(.getNotifications(model: model), completion: completion)
    }
    
    func getRegion(completion: @escaping Completion<GetRegionResponse>) {
        request(.getRegion, completion: completion)
    }
    
    func getOneNewDataResponse(model: NewRequest, completion: @escaping Completion<GetOneNewResponse>){
        request(.getOneNewData(model: model), completion: completion)
    }
    
    
    //MARK: - UpdateProfile
    func updateUser(imgData: Data,
                       avatar: String, name: String, surname: String, region_id: Int, district_id: Int, detail_address: String,
                       completion: @escaping Completion<UpdateUserResponse>) {
        // Create router.
        let router = UserRouter.updateUser
        // Create upload request.
        let request = AF.upload(multipartFormData: {
            $0.append(imgData, withName: avatar, fileName: avatar, mimeType: "image/jpeg")
            var params: [String: Any] = [:]
            params["name"] = name
            params["surname"] = surname
            params["region_id"] = region_id
            params["district_id"] = district_id
            params["detail_address"] = detail_address
            for (key, value) in params {
                guard let data = "\(value)".data(using: String.Encoding.utf8) else {continue}
                $0.append(data, withName: key as String)
                
            }
            
        }, with: router)
        
        // Track progress and handle response.
        request.responseDecodable { response in
            //            print("Data")
            ResponseMonitor<UpdateUserResponse>(response: response).monitor(completion: completion)
        }
    }
    
    func becomeCourier(passportData: Data, passport: String, pravaData: Data, prava: String, transport_type: String, completion: @escaping Completion<BecomeCourierResponse>) {
        
        // Create router.
        let router = UserRouter.becomeCourier
        // Create upload request.
        let request = AF.upload(multipartFormData: {
            $0.append(passportData, withName: passport, fileName: passport, mimeType: "image/jpeg")
            $0.append(pravaData, withName: prava, fileName: prava, mimeType: "image/jpeg")
            var params: [String: Any] = [:]
            params["transport_type"] = transport_type
            for (key, value) in params {
                guard let data = "\(value)".data(using: String.Encoding.utf8) else {continue}
                $0.append(data, withName: key as String)
                
            }
            
        }, with: router)
        
        // Track progress and handle response.
        request.responseDecodable { response in
            //            print("Data")
            ResponseMonitor<BecomeCourierResponse>(response: response).monitor(completion: completion)
        }
    }
    
    //MARK: - Get News
    func getNews(model: GetNewsRequest, completion: @escaping Completion<GetNewsResponse>) {
        request(.getNews(model: model), completion: completion)
    }
    
    //MARK: - Log Out
    func logOut(completion: @escaping Completion<LogOutResponse>) {
        request(.logOut, completion: completion)
    }
    
    //MARK: - Delete Account
    func deleteAccount(completion: @escaping Completion<DeleteAccountResponse>) {
        request(.deleteAccount, completion: completion)
    }
}
