//
//  ContentView.swift
//  Reversi


import SwiftUI
enum Stone{//マスの状態（石が置いてあるか何もおいていないか）
    case black
    case white
    case none
    
    var color:Color{//Viewの石の色(Color)を返す
        switch self{
        case .black:
            return Color.black
        case .white:
            return Color.white
        case .none:
            return Color.green
        }
    }
    
    var opposite:Stone{//反対の石の色を返す
        switch self{
        case .black:
            return Stone.white
        case .white:
            return Stone.black
        case .none:
            return Stone.none
        }
    }
}



struct Grid{//マスの状態（おいてある石、石を置いたらどの石をひっくり返すことができるか）
    var stone:Stone
    var reversibleStons:Dictionary<Stone,[(y:Int,x:Int)]> = [.black:[],.white:[]]
}



class GameManager:ObservableObject{
    @Published var matrix:[[Grid]] = []//ゲーム版の状態、２次元配列
    var playerStone:Stone = Stone.black//石を置くプレイヤー
    
    var ableToReversible:Dictionary<Stone,Bool> = [.black:false,.white:false]//黒（白）の石を置けるかどうか
    
    var numOfStones:Dictionary<Stone,Int> = [.black:0,.white:0]//黒、白の石の数
    var message:String = ""//画面上のメッセージ
    
    
    init(){
        matrix = (0...7).map{ _ in [Grid](repeating: Grid(stone: .none), count: 8)}
        setup()
    }
    
    
    func setup(){//初期化

        playerStone = .black
        message = "\(playerStone)'s turn"
        for y in 0...7{
            for x in 0...7{
                matrix[y][x].stone = Stone.none
            }
        }
        
        matrix[3][3].stone = .black
        matrix[4][4].stone = .black
        matrix[3][4].stone = .white
        matrix[4][3].stone = .white

        checkAllStatus()

    }
    
    
    func checkAllStatus(){//すべてのマスに対し石が置けるかどうか調べる
        for y in 0...7{
            for x in 0...7{
                checkReversible(y: y, x: x)
            }
        }
        
        for stone in [Stone.black,Stone.white]{
            ableToReversible[stone] = matrix.flatMap{$0}.filter{$0.reversibleStons[stone]!.count>0}.count>0//石を置くことができるか確認する
            numOfStones[stone] = matrix.flatMap{$0}.map{($0.stone == stone) ? 1:0}.reduce(0,+)//白と黒の石の数を数える
        }
    }
    
    
    func checkReversible(y:Int,x:Int){//石が置けるかどうか調べる
        
        let isInIndex = {(0...7).contains($0) && (0...7).contains($1)}
        let calc = {(i:Int,dir:Int,dis:Int)->Int in i+dir*dis}
        let directions:[(y:Int,x:Int)] = [(1,0),(1,1),(0,1),(-1,1),(-1,0),(-1,-1),(0,-1),(1,-1)]
        
        switch matrix[y][x].stone {
        case .none:
            for stone in [Stone.black,Stone.white]{
                
                self.matrix[y][x].reversibleStons[stone]!.removeAll()
                
                for direction in directions{
                    var distance = 1
                    if isInIndex(calc(y,direction.y,distance),calc(x,direction.x,distance)){
                        while matrix[calc(y,direction.y,distance)][calc(x,direction.x,distance)].stone == stone.opposite{
                            distance += 1
                            if !isInIndex(calc(y,direction.y,distance),calc(x,direction.x,distance)){
                                break
                            }
                            if matrix[calc(y,direction.y,distance)][calc(x,direction.x,distance)].stone == stone{
                                self.matrix[y][x].reversibleStons[stone]! += (1..<distance).map{(y: calc(y,direction.y,$0), x: calc(x,direction.x,$0))}
                            }
                        }
                    }
                }
            }
        case .black,.white:
            matrix[y][x].reversibleStons =  [.black:[],.white:[]]
        }
    }
    
    
    func reverse(y:Int,x:Int){//ひっくり返す
        if matrix[y][x].reversibleStons[playerStone]!.count>0{
            matrix[y][x].stone = playerStone
            for reverseStone in matrix[y][x].reversibleStons[playerStone]!{
                let x = reverseStone.x
                let y = reverseStone.y
                matrix[y][x].stone = playerStone
            }
            checkAllStatus()//ひっくり返した後にすべてのマスに対し石が置けるかどうか調べる
            checkGameStatus()//ゲームのターンを交代する。もしくはゲームを終了する。
        }
    }
    
    
    func checkGameStatus(){//ゲームのターンを交代する。もしくはゲームを終了する。
        playerStone = ableToReversible[playerStone.opposite]! ? playerStone.opposite:playerStone
        message = "\(playerStone)'s turn"
        
        if (!(ableToReversible[playerStone]! || ableToReversible[playerStone.opposite]!)){//ゲーム終了時の処理
            let winner = (numOfStones[.black]!>numOfStones[.white]!) ? Stone.black:Stone.white
            message = "GAME SET! won by \(winner)"
            numOfStones[.black] == numOfStones[.white] ? message = "DRAW":nil
        }
    }
}



struct ContentView: View {
    
    @ObservedObject var gameManager:GameManager = GameManager()
    
    var body: some View {
        VStack{
            Button(action: {gameManager.setup()}){Text("RESET")}
            Text(gameManager.message)
            LazyVGrid(columns:Array(repeating: GridItem(spacing:0), count: 8),spacing:0){
                ForEach(0...63, id: \.self){i in
                    ZStack{
                        Rectangle()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                            .border(Color.black, width: 1)
                        Circle()
                            .frame(width: 40, height: 40)
                            .foregroundColor(gameManager.matrix[i/8][i%8].stone.color)
                    }.onTapGesture {
                        withAnimation{
                        gameManager.reverse(y: i/8, x: i%8)
                        }
                    }
                }
            }
            Text("BLACK:\(gameManager.numOfStones[.black]!) WHITE:\(gameManager.numOfStones[.white]!)")
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}
