//
//  ParticleScene.swift
//  ParticlesConnectedEffect
//
//  Created by Artturi Jalli on 7.1.2021.
//

import SpriteKit
import GameplayKit

class ParticleScene: SKScene {
    
    let offset = CGFloat(1.0)
    let travelDistance = CGFloat(1500.0)
    let bgColor = UIColor(red: 1/255, green: 48/255, blue: 63/255, alpha: 1)
    let edges: [ScreenEdge] = [.Left, .Right, .Bottom, .Top]
    let numParticles = 30
    var particles: [Particle] = []
    
    enum ScreenEdge {
        case Left
        case Right
        case Top
        case Bottom
    }
    
    class Particle {
        let node: SKShapeNode
        let scene: SKScene
        var connectingLines: [SKShapeNode] = []
        var connectedParticles: [Particle] = []
        
        init(node: SKShapeNode, scene: SKScene, position: CGPoint) {
            self.node = node
            self.node.position = position
            self.node.fillColor = .white
            self.scene = scene
        }
        
        func position() -> CGPoint {
            return self.node.position
        }
        
        func move(target: CGPoint){
            self.node.run(SKAction.move(to: target, duration: TimeInterval(Int.random(in: 20...40))))
        }
        
        func addToScene(){
            self.scene.addChild(node)
        }
        
        func destroyFromScene(){
            self.node.removeFromParent()
        }
        
        func distance(_ otherParticle: Particle) -> CGFloat {
            return self.position().distanceTo(otherParticle.position())
        }
        
        func connectWithLine(_ otherParticle: Particle) {
            let line = SKShapeNode()
            let pathToDraw = CGMutablePath()
            pathToDraw.move(to: self.position())
            pathToDraw.addLine(to: otherParticle.position())
            line.path = pathToDraw
            line.alpha = 50.0 / self.distance(otherParticle) - 0.2
            line.strokeColor = .white
            scene.addChild(line)
            connectingLines.append(line)
            self.connectedParticles.append(otherParticle)
            otherParticle.connectedParticles.append(self)
        }
        
        func isConnectedTo(_ otherParticle: Particle) -> Bool {
            if self.connectedParticles.contains(where: { (part) -> Bool in
                part === otherParticle
            }) {
                return true
            } else {
                return false
            }
        }
        
        func removeConnectingLines(){
            for line in connectingLines {
                line.removeFromParent()
            }
            connectedParticles = []
            connectingLines = []
        }
    }
    
    func particleTargetPos(r: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPoint(x: r * cos(angle), y: r * sin(angle))
    }
    
    func randPosAndTarget() -> (CGPoint, CGPoint) {
        let randomEdge = edges[Int.random(in: 0...edges.count - 1)]
        
        let frameWidthRandomRange = -frame.size.width/2 ... frame.size.width/2
        let frameHeightRandomRange = -frame.size.height/2 ... frame.size.height/2
        
        switch randomEdge {
        case .Left:
            let particlePosition = CGPoint(x: -frame.size.width / 2 + offset, y: CGFloat.random(in: frameHeightRandomRange))
            let angle = CGFloat.random(in: -CGFloat.pi / 2 ... CGFloat.pi / 2)
            return (particlePosition, particleTargetPos(r: travelDistance, angle: angle))
        case .Right:
            let particlePosition = CGPoint(x: frame.size.width / 2 - offset, y: CGFloat.random(in: frameHeightRandomRange))
            let angle = CGFloat.random(in: CGFloat.pi / 2 ... 3 * CGFloat.pi / 2)
            return (particlePosition, particleTargetPos(r: travelDistance, angle: angle))
        case .Top:
            let particlePosition = CGPoint(x: CGFloat.random(in: frameWidthRandomRange), y: frame.size.height/2 - offset)
            let angle = CGFloat.random(in: -CGFloat.pi ... 0.0)
            return (particlePosition, particleTargetPos(r: travelDistance, angle: angle))
        case .Bottom:
            let particlePosition = CGPoint(x: CGFloat.random(in: frameWidthRandomRange), y: -frame.size.height/2 + offset)
            let angle = CGFloat.random(in: 0 ... CGFloat.pi)
            return (particlePosition, particleTargetPos(r: travelDistance, angle: angle))
        }
    }
    
    func createParticle(atPos: CGPoint, target: CGPoint) {
        let particle = Particle(node: SKShapeNode(circleOfRadius: 3), scene: self, position: atPos) // Size of Circle
        particle.move(target: target)
        particles.append(particle)
        particle.addToScene()
    }
    
    func assignInitialParticles() {
        for _ in 1...numParticles {
            let target = particleTargetPos(r: travelDistance, angle: CGFloat.random(in: 0.0 ... 2 * CGFloat.pi))
            let initialPosition = CGPoint(x: CGFloat.random(in: -frame.size.width / 2 ... frame.size.width / 2),
                              y: CGFloat.random(in: -frame.size.height / 2 ... frame.size.height / 2))
            createParticle(atPos: initialPosition, target: target)
        }
    }
    
    func connectParticles() {
        for particle in particles {
            for particleNeighbor in closestParticles(toParticle: particle) {
                if particle.distance(particleNeighbor) < 250 && !particle.isConnectedTo(particleNeighbor) {
                    particle.connectWithLine(particleNeighbor)
                }
            }
        }
    }
    
    func closestParticles(toParticle: Particle) -> [Particle]{
        return particles.sorted(by: {
            $0.distance(toParticle) < $1.distance(toParticle)
        })
    }
    
    func handleParticleUpdates() {
        for i in 0...particles.count - 1 {
            let particle = particles[i]
            if !particle.position().intersects(self.frame) {
                particle.destroyFromScene()
                particles.remove(at: i)
                
                let positionAndTarget = randPosAndTarget()
                createParticle(atPos: positionAndTarget.0, target: positionAndTarget.1)
            }
        }
    }
    
    func destroyAllConnectingLines() {
        for particle in particles {
            particle.removeConnectingLines()
        }
    }
    
    override func didMove(to view: SKView) {
        self.backgroundColor = bgColor
        assignInitialParticles()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        destroyAllConnectingLines()
        handleParticleUpdates()
        connectParticles()
    }
}

extension CGPoint {
    func distanceTo(_ anotherPoint: CGPoint) -> CGFloat {
        return sqrt(pow(self.x - anotherPoint.x, 2) + pow((self.y - anotherPoint.y), 2))
    }
    
    func intersects(_ frame: CGRect) -> Bool {
        return self.x > -frame.size.width / 2 && self.x < frame.size.width / 2 &&
            self.y > -frame.size.height / 2 && self.y < frame.size.height / 2
    }
}
