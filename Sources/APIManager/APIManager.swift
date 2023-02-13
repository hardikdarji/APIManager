import Foundation

public enum RequestType: String{
    case GET, POST
}
// APIError enum which shows all possible Network errors
public enum AppError: Error {
    case networkError(Error)
    case dataNotFound
    case jsonParsingError(Error)
    case invalidStatusCode(Int)
    case badURL(String)
    case badResponse(Error)
}
// Result enum to show success or failure
public enum Result<T> {
    case success(T)
    case failure(AppError)
}

public class APIManager{
    public init() {}
    public func requestData<T: Decodable>(strUrl: String,
                                   type: RequestType = .GET,
                                   objectType: T.Type,
                                   para: [String: Any]? = nil,
                                   completion: @escaping (Result<T>)-> Void)
    {
        //create url
        guard let url = URL(string: strUrl)
        else {return}
        
        //create session
        let session = URLSession.shared
        
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { data, response, error in
            
            guard error == nil else {
                completion(Result.failure(AppError.networkError(error!)))
                return
            }
            
            guard let data = data else {
                completion(Result.failure(AppError.dataNotFound))
                return
            }
            
            do {
                // create decodable object from data
                let decodedObject = try JSONDecoder().decode(objectType.self, from: data)
                completion(Result.success(decodedObject))
            } catch let error {
                completion(Result.failure(AppError.jsonParsingError(error as! DecodingError)))
            }
        }
        task.resume()
    }
    
    @available(iOS 15.0.0, *)
    public func fetchData<T: Decodable>(strUrl: String,
                                   type: RequestType = .GET,
                                   objectType: T.Type,
                                   para: [String: Any]? = nil) async -> Result<T>
    {
        //create url
        guard let url = URL(string: strUrl)
        else { return Result.failure(AppError.badURL(strUrl))}
        
        // ... some asynchronous networking code ...
        do{
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let code = (response as? HTTPURLResponse)?.statusCode,
                  code == 200 else {
                return Result.failure(AppError.invalidStatusCode((response as? HTTPURLResponse)!.statusCode))
            }
            do {
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                return Result.success(decodedObject)
            }
            catch let error{
                return Result.failure(AppError.jsonParsingError(error))
            }
        }catch let error{
            return Result.failure(AppError.badResponse(error))
        }
    }
    
}
