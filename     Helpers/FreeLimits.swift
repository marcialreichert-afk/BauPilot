import Foundation

enum AppLimits {
    
    static var maxBaustellen: Int {
        AppConfig.isProUser ? Int.max : 2
    }
    
    static var maxEintraegeProBaustelle: Int {
        AppConfig.isProUser ? Int.max : 20
    }
    
    static var maxFotosProEintrag: Int {
        AppConfig.isProUser ? Int.max : 2
    }
    
    static var maxNachweiseProBaustelle: Int {
        AppConfig.isProUser ? Int.max : 2
    }
    
    static var maxAufmasseProBaustelle: Int {
        AppConfig.isProUser ? Int.max : 1
    }
    
    static var maxFotosProAufmass: Int {
        AppConfig.isProUser ? Int.max : 1
    }
}
