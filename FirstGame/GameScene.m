//
//  GameScene.m
//  FirstGame
//
//  Created by Jordan Rodrigues Rangel on 1/28/15.
//  Copyright (c) 2015 Jordan Rodrigues Rangel. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "GameScene.h"
#import "GridClass.h"
#import "TowerClass.h"
#import "Enemy.h"
#include "Algebra.h"
#include "CollisionCategories.h"
#import "GameOverScene.h"
#import "RankingScene.h"
#import "SingleShot.h"
#import "Red.h"


#define COLS 16
#define LINS 16
#define MONSTERS_SIZE 5
#define TOWERS_SIZE 10
#define NUMBER_OF_LIVES 50
#define NUMBER_OF_REDS 50

static NSString * const kTowerNodeName = @"movable";

@interface GameScene() <SKPhysicsContactDelegate>

{
    GridClass * matrix[LINS][COLS];
//    GridClass ** path;
}

@property (nonatomic) float gridCellWidth;
@property (nonatomic) float gridCellHeight;
@property (nonatomic, strong) TowerClass *selectedNode;
@property (nonatomic) CGPoint originalSelectedNodePosition;
@property (nonatomic) NSMutableArray *monsters;
@property (nonatomic) NSMutableArray *reds;
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastRedSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) int monstersRespawned;
@property (nonatomic) int redsRespawned;
@property (nonatomic) NSMutableArray * towers;
@property (nonatomic) int towersCreated;

//Propriedades do jogo
@property (nonatomic) int lives;
@property (nonatomic) BOOL playable;
@property (nonatomic) SKLabelNode *livesLabel;
@property (nonatomic) UIButton *roundButton;
@property (nonatomic) int currentRound;
@property (nonatomic) SKLabelNode *currentRoundLabel;
@property (nonatomic) int score;
@property (nonatomic) SKLabelNode *scoreLabel;
@property (nonatomic) BOOL extraRound;
@property (nonatomic) int coins;
@property (nonatomic) NSMutableArray * towersFromMenu;

@property (nonatomic) NSMutableArray * enemyPath;
@property (nonatomic) NSMutableArray * redPath;

@property (nonatomic) int monstersOut;

@end

@implementation GameScene

-(id)initWithSize:(CGSize)size {
    
    if (self = [super initWithSize:size]) {
        
        NSLog(@"%f x %f y",size.width, size.height);
        
        // Imagem Background
        SKSpriteNode * background = [[SKSpriteNode alloc] initWithImageNamed:@"Background4.png"];
        background.position = CGPointMake(size.width/2.0f, size.height/2.0f);
        background.size = size;
        
        [self addChild:background];
        //FIM - Imagem Background
        
        //Coins do Usuário
        self.coins = 100;
        //FIM
        
        //Codigo do Grid
        self.gridCellHeight = size.height/LINS;
        self.gridCellWidth = size.width/COLS;
        
        //Caminho
        [self createPath:0];
        //FIM-Caminho
        
        //Menu
        [self createMenu];
        //FIM-Menu
        
        //PLACEHOLDERS
        [self setPlaceHolders];
        //FIM-PLACEHOLDERS
        
        //Inicializa a física
        self.physicsWorld.gravity = CGVectorMake(0,0);
        self.physicsWorld.contactDelegate = self;
        //FIM - Inicializa a física
        
        
        //Inicializa as vidas do jogador.
        self.lives = NUMBER_OF_LIVES;
        CGPoint labelPosition = CGPointMake([matrix[LINS-2][COLS-3] gridCenter].x + self.gridCellWidth/2.0f,[matrix[LINS-2][COLS-1] gridCenter].y);
        self.livesLabel = [[SKLabelNode alloc] init];
        self.livesLabel.position = labelPosition;
        self.livesLabel.fontSize = 10.0f;
        self.livesLabel.text = [NSString stringWithFormat:@"Vidas: %d", self.lives];
        self.livesLabel.fontColor = [UIColor whiteColor];
        self.livesLabel.fontName = @"ChalkboardSE-Bold";
        [self addChild:self.livesLabel];
        //FIM
        
        //Botao de Rounds
        self.playable = NO;
        self.roundButton = [[UIButton alloc] initWithFrame:CGRectMake([matrix[0][5] gridCenter].x - (self.gridCellWidth/2), size.height - [matrix[0][6] gridCenter].y - (self.gridCellHeight/2), 6*self.gridCellWidth, self.gridCellHeight)];
        [self.roundButton setTitle:@"Começar Round" forState:UIControlStateNormal];
        self.roundButton.backgroundColor = [[UIColor alloc] initWithRed:0.9f green:0.2f blue:0.6f alpha:0.6];
        [self.roundButton addTarget:self action:@selector(startRound) forControlEvents:UIControlEventTouchUpInside];
        //FIM-Botão de Rounds
        
        //Label de Rounds
        self.currentRound = 0;
        self.currentRoundLabel = [[SKLabelNode alloc] init];
        self.currentRoundLabel.fontSize = 10.0f;
        self.currentRoundLabel.text = @"Nível: 1";
        self.currentRoundLabel.fontColor = [UIColor whiteColor];
        self.currentRoundLabel.fontName = @"ChalkboardSE-Bold";
        self.currentRoundLabel.position = CGPointMake(size.width/2.0f, [matrix[LINS-2][COLS-1] gridCenter].y);
        [self addChild:self.currentRoundLabel];
        //FIM-Label de Rounds
        
        //Label de Score
        self.score = 0;
        self.scoreLabel = [[SKLabelNode alloc] init];
        self.scoreLabel.fontSize = 10.0f;
        self.scoreLabel.text = [NSString stringWithFormat:@"Pontos: %d", self.score];
        self.scoreLabel.fontColor = [UIColor whiteColor];
        self.scoreLabel.fontName = @"ChalkboardSE-Bold";
        self.scoreLabel.position = CGPointMake(self.scoreLabel.frame.size.width/2, [matrix[LINS-2][COLS-1] gridCenter].y);
        [self addChild:self.scoreLabel];
        //FIM
        
    }
    
    return self;
}

//Método de carregamento de elementos após carregamento inicial da scene.
-(void)didMoveToView:(SKView *)view
{
    [self.view addSubview: self.roundButton];
    
}

//Método de quando se toca a tela.
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //Encontra aonde o toque foi feito
    UITouch *touch = [touches anyObject];
    
    CGPoint positionInScene = [touch locationInNode:self];
    
    //Chama o método para lidar com o toque.
    [self selectNodeForTouch:positionInScene];
}


- (void)selectNodeForTouch:(CGPoint)touchLocation {
    
    //Marca o node selecionado.
    SKSpriteNode *touchedNode = (SKSpriteNode *)[self nodeAtPoint:touchLocation];
    
    //Veirifica se é um novo node selecionado.
    if(![_selectedNode isEqual:touchedNode] && [[touchedNode name] isEqualToString:kTowerNodeName]) {
        
        //Ajeita a posição do node.
        if(_selectedNode)
        {
            [_selectedNode removeAllActions];
            _selectedNode.zRotation = 0.0f;
            //[_selectedNode runAction:[SKAction rotateToAngle:0.0f duration:0.01]];
        }
        
        //O marca como o selecionado.
        _selectedNode = (TowerClass *) touchedNode;
        
        //Se for uma torre.
        if(self.coins >= [_selectedNode getCost]) {
            
            //Guarda a posição original.
            self.originalSelectedNodePosition = self.selectedNode.position;
            
            //Aniamação de rotação enquanto o node está selecionado.
            SKAction *sequence = [SKAction sequence:@[[SKAction rotateByAngle:degToRad(-4.0f) duration:0.1],
                                                      [SKAction rotateByAngle:0.0 duration:0.1],
                                                      [SKAction rotateByAngle:degToRad(4.0f) duration:0.1]]];
            [_selectedNode runAction:[SKAction repeatActionForever:sequence]];
        }
        else
        {
            _selectedNode = nil;
        }
    }
    
}

//Método de quando o usuário solta a tela.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if(!_selectedNode)
        return;
    
    //Guarda a posição do node selecionado.
    CGPoint position = [_selectedNode position];
    
    //Se for torre.
    if([[_selectedNode name] isEqualToString:kTowerNodeName]) {
        
        //Descobre o gridcell que agora falta uma torre
        int line = (int) position.y/self.gridCellHeight;
        int col = (int) position.x/self.gridCellWidth;
        
        //Se tem espaco, coloca uma torre.
        if([matrix[line][col] placeTower])
        {
            self.coins -= [_selectedNode getCost];
            
            //Pega a pos. e o tam. do grid.
            CGPoint positionInGrid = [matrix[line][col] gridCenter];
            
            //Cria uma nova Torre
            TowerClass * menuSprite = [[TowerClass alloc] initWithType:[_selectedNode getType]];
            menuSprite.lastSpawnTimeInterval = 5;
            menuSprite.size = CGSizeMake(menuSprite.size.width/40.0f, menuSprite.size.height/40.0f);
            [menuSprite setName:kTowerNodeName];
            menuSprite.position = self.originalSelectedNodePosition;
            
            if([menuSprite getCost] > self.coins)
                menuSprite.colorBlendFactor = 0.75f;
            
            [self addChild:menuSprite];
            
            //Coloca a torre na posicao nova.
            [_selectedNode setName:@"jaFoiColocadoNaGridCell"];
            [_selectedNode setPosition:positionInGrid];
            [self.towers addObject:_selectedNode];
            
            [_selectedNode removeAllActions];
            [self.towersFromMenu removeObject:_selectedNode];
            [_selectedNode runAction:[SKAction rotateToAngle:0.0f duration:0.1]];
            _selectedNode = nil;
            
            //Nova torre do Menu
            [self.towersFromMenu addObject:menuSprite];
            
        }
        //Se nao tem espaço, volta pro lugar do menu.
        else
        {
            [_selectedNode setPosition:self.originalSelectedNodePosition];
        }
    }
}

//Método pra imagem seguir o toque do usuário.
- (void)panForTranslation:(CGPoint)translation {
    CGPoint position = [_selectedNode position];
    
    if([[_selectedNode name] isEqualToString:kTowerNodeName]) {
        [_selectedNode setPosition:CGPointMake(position.x + translation.x, position.y + translation.y)];
    }
}

//Método de movimento do toque.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    
    CGPoint positionInScene = [touch locationInNode:self];
    
    CGPoint previousPosition = [touch previousLocationInNode:self];
    
    CGPoint translation = CGPointMake(positionInScene.x - previousPosition.x, positionInScene.y - previousPosition.y);
    
    [self panForTranslation:translation];
}

//Método Update.
- (void)update:(NSTimeInterval)currentTime{
    
    //Checa pra ver se o usuario ja pode comprar as torres
    for(TowerClass * tower in self.towersFromMenu)
    {
        if([tower getCost] <= self.coins)
            tower.colorBlendFactor = 0.0;
    }
    
    if(!self.playable)
        return;
    
    //Calcula o tempo desde o ultimo update.
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    
    //Teste de erro
    if(timeSinceLast > 1){
        timeSinceLast = 1.0f/60.0f;
        self.lastUpdateTimeInterval = currentTime;
    }
    
    //Chama o update passando o intervalo de tempo do ultimo update.
    [self updateWithTimeSinceLastUpdate: timeSinceLast];
}

// Update com intervalo
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast{
    
    //Testa pra ver se ainda há monstros no round.
    if(self.monstersOut < [self.monsters count])
    {
        //Respawn de monstros
        self.lastSpawnTimeInterval += timeSinceLast;
        
        if(self.lastSpawnTimeInterval > 0.5  && self.playable && self.monstersRespawned < [self.monsters count])
        {
            self.lastSpawnTimeInterval = 0;
        
            //Cria ponteiro pro monstro.
            Enemy * enemy = self.monsters[self.monstersRespawned];
            self.monstersRespawned ++;
        
            [self addChild:enemy];
        
            //Cria o caminho a ser percorrido pelo monstro.
            float pathLength = 0.0f;
        
            CGMutablePathRef actionPath = CGPathCreateMutable();
            CGPathMoveToPoint(actionPath, NULL, enemy.position.x, enemy.position.y);
            
            int pathSize = [self.enemyPath count];
            
            for(int i=0;i<pathSize;i++)
            {
                CGPathAddLineToPoint(actionPath, NULL, [self.enemyPath[i] gridCenter].x, [self.enemyPath[i] gridCenter].y);
                if(i < (pathSize-1))
                    pathLength += rwLength(rwSub([self.enemyPath[i+1] gridCenter], [self.enemyPath[i] gridCenter]));
            }
        
            pathLength += self.gridCellWidth/2.0f + enemy.size.width/2.0f;
            CGPathAddLineToPoint(actionPath, NULL, [self.enemyPath[pathSize-1] gridCenter].x + self.gridCellWidth/2.0f + enemy.size.width/2.0f, [self.enemyPath[pathSize-1] gridCenter].y);
        
            //Envia o caminho a ser percorrido para o monstro.
            [enemy moveTo:actionPath pathLength:pathLength gameScene:self];
        
        }
        
        //Criação dos Reds
        if(self.extraRound)
        {
            self.lastRedSpawnTimeInterval +=timeSinceLast;
            
            if(self.lastRedSpawnTimeInterval > 0.2  && self.playable && self.redsRespawned < [self.reds count])
            {
                self.lastRedSpawnTimeInterval = 0;
                
                //Cria o ponteiro para o Red
                Red * red = self.reds[self.redsRespawned];
                self.redsRespawned++;
                
                [self addChild:red];
                
                //Cria o caminho a ser percorrido pelo Red.
                float pathLength = 0.0f;
                
                CGMutablePathRef actionPath = CGPathCreateMutable();
                CGPathMoveToPoint(actionPath, NULL, red.position.x, red.position.y);
                
                int pathSize = [self.redPath count];
                
                for(int i=0;i<pathSize;i++)
                {
                    CGPathAddLineToPoint(actionPath, NULL, [self.redPath[i] gridCenter].x, [self.redPath[i] gridCenter].y);
                    if(i < (pathSize-1))
                        pathLength += rwLength(rwSub([self.redPath[i+1] gridCenter], [self.redPath[i] gridCenter]));
                }
                
                pathLength += self.gridCellWidth/2.0f + red.size.width/2.0f;
                CGPathAddLineToPoint(actionPath, NULL, [self.redPath[pathSize-1] gridCenter].x + self.gridCellWidth/2.0f + red.size.width/2.0f, [self.redPath[pathSize-1] gridCenter].y);
                
                //Envia o caminho a ser percorrido para o Red.
                [red moveTo:actionPath pathLength:pathLength gameScene:self];
            }
            
        }
        
        [self towerMonitoringwithTimeSinceLastUpdate: timeSinceLast];
    }
    else
    {
        //Testa pra ver se o usuário ganhou a fase.
        if(self.currentRound == 10)
        {
            SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
            SKScene * gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:YES score:self.score];
            
            [self removeViewsFromSuperView];
            
            [self.view presentScene:gameOverScene transition: reveal];
        }
        //Se não ganhou ainda, pausa o jogo.
        else
        {
            self.playable = NO;
            self.roundButton.hidden = NO;
        }
    }
}

// Método de monitoramento das torres
- (void) towerMonitoringwithTimeSinceLastUpdate: (CFTimeInterval)timeSinceLast
{
    //Monitoramento de cada torre.
    for(TowerClass * tower in self.towers)
    {
        tower.lastSpawnTimeInterval += timeSinceLast;
        
        //Se ja deu o tempo de intervalo entre tiros.
        if(tower.lastSpawnTimeInterval > [tower getDelay])
            //Para cada inimigo.
            for(Enemy * enemy in self.monsters)
            {
                if(![enemy getIsActive])
                    continue;
                
                BOOL didShoot = NO;
                
                tower.lastSpawnTimeInterval = 0;
                
                
                //Calcula a distancia da torre ate o inimigo.
                CGPoint direction = rwSub(enemy.position, tower.position);
                float distance = rwLength(direction);
                
                //Se o inimigo está dentro do alcance da torre.
                if(distance <= [tower getRange] )
                {
                    
                    switch([tower getType])
                    {
                        case INDIANTOWER:
                        {
                            SingleShot * projectile = [[SingleShot alloc] initWithImageNamed:@"arrow.png" inPosition:tower.position powerDamage:30];
                            
                            [projectile shootEnemyIn:direction withDuration:1.0f];
                            [self addChild:projectile];
                            break;
                        }
                            
                        case SPACETOWER:
                        {
                            break;
                        }
                            
                        case HERO:
                        {
                            break;
                        }
                            
                        case BOMBTOWER:
                        {
                            break;
                        }
                            
                        case FIRETOWER:
                        {
                            break;
                        }
                        
                        default:
                        {
                            break;
                        }
                            
                    }
                    
                    didShoot = YES;
                }
                
                if(didShoot)
                    break;
            }
    }
}

//Método que identifica o contato entre nodes.
- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    //Se ocorreu o contato entre monstro e projetil
    if ((firstBody.categoryBitMask & projectileCategory) != 0 &&
        (secondBody.categoryBitMask & monsterCategory) != 0)
    {
        [self projectile:(ProjectileClass *) firstBody.node didCollideWithMonster:(Enemy *) secondBody.node];
    }
    
    if ((firstBody.categoryBitMask & monsterCategory) != 0 &&
        (secondBody.categoryBitMask & redCategory) != 0)
    {
        Red * red = (Red*) secondBody.node;
        [red killRed];
        
    }
}

// Método que trata a colisão entre projétil e monstro
- (void)projectile:(ProjectileClass *)projectile didCollideWithMonster:(Enemy *)monster {
   
    if([projectile isKindOfClass:[SingleShot class]])
    {
        [projectile removeFromParent];
        
        //Quando mata o monstro, entra no if.
        if([monster causeDamage:[projectile getPowerDamage]])
        {
            //Menos um monstro no round.
            self.monstersOut++;
            [monster removeFromParent];
            
            //Ganha o dinheiro
            self.coins += [monster getReward];
            
            //Só ganha pontos se não for fase extra.
            if(!self.extraRound)
            {
                self.score+= [monster monsterScore];
                self.scoreLabel.text = [NSString stringWithFormat:@"Pontos: %d", self.score];
                self.scoreLabel.position = CGPointMake(self.scoreLabel.frame.size.width/2, [matrix[LINS-2][COLS-1] gridCenter].y);
            }
        }
    }
}

//Método para remover vidas do usuário
- (void) removeLife:(int)damage
{
    
    //Menos um monstro no jogo.
    self.monstersOut++;
    
    //Tira a vida do usuário.
    if(!self.extraRound)
    {
        self.lives-= damage;
    }
    
    //Não deixa vida negativa.
    if(self.lives < 0) self.lives = 0;
    
    //Atualiza mostrador de vidas.
    self.livesLabel.text = [NSString stringWithFormat:@"Vidas: %d", self.lives];
    
    //Se o usuário perdeu, termina o jogo.
    if(self.lives == 0)
    {
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        SKScene * gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:NO score:self.score];
        
        [self removeViewsFromSuperView];
        
        [self.view presentScene:gameOverScene transition: reveal];
    }
}

//Método auxiliar para consertar interface.
-(void)removeViewsFromSuperView
{
    if(self.roundButton)
    {
        [self.roundButton removeFromSuperview];
        self.roundButton = nil;
    }
}

//Função que começa o round.
- (void) startRound
{
    
    //Atualizações de novo round.
    self.roundButton.hidden = YES;
    self.monstersOut = 0;
    self.lastSpawnTimeInterval = 5;
    self.playable = YES;
    
    //Fase extra.
    if(self.currentRound%2==0 && !self.extraRound && self.currentRound!=0)
    {
        self.currentRoundLabel.text = @"Nível Extra!";
        self.extraRound = YES;
        self.redsRespawned = 0;
        [self createReds];
        
        //Mostrar entrada dos reds
        for (GridClass *grid in self.redPath)
        {
            if([grid getGridCellTerrain] == PATHRED)
            {
                grid.pathNode.hidden = NO;
            }
        }
        
    }
    //Fase regular
    else
    {
        self.extraRound = NO;
        self.currentRound++;
        self.currentRoundLabel.text = [NSString stringWithFormat:@"Nível: %d", self.currentRound];
        
        //Mostrar entrada dos reds
        for (GridClass *grid in self.redPath)
        {
            if([grid getGridCellTerrain] == PATHRED)
            {
                grid.pathNode.hidden = YES;
            }
        }
    }
    
    [self createMonsters];

}

//Método de criação do path.
-(void)createPath:(int)level
{
    NSString * scenePath = [[NSBundle mainBundle] pathForResource:@"sceneConfig" ofType:@".txt"];
    
    FILE* sceneConfig = fopen([scenePath UTF8String], "r");
    char strTemp[100];
    char levelString[10];
    char charTemp;
    
    sprintf(levelString, "#level-%d#", level);
    
    if(!sceneConfig)
    {
        NSLog(@"Error - couldn't open sceneConfig.txt");
        exit(-1);
    }
    
    fscanf(sceneConfig, " %[^\n]", strTemp);
    
    while(strcmp(strTemp, levelString))
    {
        fscanf(sceneConfig, " %[^\n]", strTemp);
    }
    
    int index;
    
    self.enemyPath = [[NSMutableArray alloc] init];
    self.redPath = [[NSMutableArray alloc] init];
    
    //EnemyOnly
    while(fscanf(sceneConfig, "%d", &index) == 1)
    {
        int lin = index / COLS;
        int col = index % LINS;
        
        matrix[lin][col] = [[GridClass alloc] initWithI:lin withJ:col ofTerrain:PATHENEMY withSize:CGSizeMake(self.gridCellWidth, self.gridCellHeight)];
        
        //Cria os sprites do caminho e coloca na tela
        SKSpriteNode * pathCell = [SKSpriteNode spriteNodeWithColor:[[UIColor alloc] initWithRed:lin/8.0f green:col/8.0f blue:arc4random_uniform(64)/64.0f alpha:0.5f] size:CGSizeMake(self.gridCellWidth, self.gridCellHeight)];
        
        matrix[lin][col].pathNode = pathCell;
        
        pathCell.anchorPoint = CGPointZero;
        pathCell.position = matrix[lin][col].position;
        [self addChild:pathCell];
        
        [self.enemyPath addObject:matrix[lin][col]];
    }
    fscanf(sceneConfig,"%c",&charTemp);
    
    //RedOnly
    while(fscanf(sceneConfig, "%d", &index) == 1)
    {
        int lin = index / COLS;
        int col = index % LINS;
        
        matrix[lin][col] = [[GridClass alloc] initWithI:lin withJ:col ofTerrain:PATHRED withSize:CGSizeMake(self.gridCellWidth, self.gridCellHeight)];
        
        //Cria os sprites do caminho e coloca na tela
        SKSpriteNode * pathCell = [SKSpriteNode spriteNodeWithColor:[[UIColor alloc] initWithRed:lin/8.0f green:col/8.0f blue:arc4random_uniform(64)/64.0f alpha:0.5f] size:CGSizeMake(self.gridCellWidth, self.gridCellHeight)];
        
        matrix[lin][col].pathNode = pathCell;
        
        pathCell.anchorPoint = CGPointZero;
        pathCell.position = matrix[lin][col].position;
        pathCell.hidden = YES;
        [self addChild:pathCell];
        [self.redPath addObject:matrix[lin][col]];
    }
    fscanf(sceneConfig,"%c",&charTemp);
    
    //Both
    while(fscanf(sceneConfig, "%d", &index) == 1)
    {
        int lin = index / COLS;
        int col = index % LINS;
        
        matrix[lin][col] = [[GridClass alloc] initWithI:lin withJ:col ofTerrain:PATHBOTH withSize:CGSizeMake(self.gridCellWidth, self.gridCellHeight)];
        
        //Cria os sprites do caminho e coloca na tela
        SKSpriteNode * pathCell = [SKSpriteNode spriteNodeWithColor:[[UIColor alloc] initWithRed:lin/8.0f green:col/8.0f blue:arc4random_uniform(64)/64.0f alpha:0.5f] size:CGSizeMake(self.gridCellWidth, self.gridCellHeight)];
        
        matrix[lin][col].pathNode = pathCell;
        
        pathCell.anchorPoint = CGPointZero;
        pathCell.position = matrix[lin][col].position;
        [self addChild:pathCell];
        
        [self.enemyPath addObject:matrix[lin][col]];
        [self.redPath addObject:matrix[lin][col]];
    }
    
    
    fclose(sceneConfig);
}

//Método que separa as duas linhas superiores e inferiores de grid como NIL e a posição das torres como MENU.
-(void) createMenu
{
    //Duas linhas superiores
    for(int lin = 0; lin < 2; lin++)
    {
        for(int col = 0; col < COLS; col++)
        {
            matrix[lin][col] = [[GridClass alloc] initWithI:lin withJ:col ofTerrain:NIL withSize:CGSizeMake(self.gridCellWidth, self.gridCellHeight)];
        }
    }
    
    //Uma linha inferior
    for(int lin = LINS-1; lin < LINS; lin++)
    {
        for(int col = 0; col < COLS; col++)
        {
            matrix[lin][col] = [[GridClass alloc] initWithI:lin withJ:col ofTerrain:NIL withSize:CGSizeMake(self.gridCellWidth, self.gridCellHeight)];
        }
    }
    
    //Criação do menu de torres
    TypeOfTower towerTypes[NUMOFTOWERTYPES] = {INDIANTOWER,SPACETOWER,BOMBTOWER,FIRETOWER,HERO};
    self.towersFromMenu = [[NSMutableArray alloc] initWithCapacity:NUMOFTOWERTYPES];
    
    for(int i=0; i < NUMOFTOWERTYPES; i++)
    {
        //Cria a torre
        TowerClass *sprite = [[TowerClass alloc] initWithType:towerTypes[i]];
        
        //Intervalo de Respawn
        sprite.lastSpawnTimeInterval = 5;
        
        //Tamanho de um frame
        sprite.size = CGSizeMake(sprite.size.width/40.0f, sprite.size.height/40.0f);
        
        //Nomeia o sprite
        [sprite setName:kTowerNodeName];
        
        //Determina a posição da torre
        int col = COLS-1 - i;
        
        matrix[2][col] = [[GridClass alloc] initWithI:2 withJ:col ofTerrain:MENU withSize:CGSizeMake(self.gridCellWidth, self.gridCellHeight)];
        
        CGPoint cellCenter = matrix[2][col].gridCenter;
        
        [sprite setPosition:cellCenter];
        
        //Verifica se o usuário tem o dinheiro para esta torre. Se não tiver, escurece a imagem.
        if([sprite getCost] > self.coins)
        {
            sprite.colorBlendFactor = 0.75f;
        }
        
        //Adiciona a torre
        [self addChild:sprite];
        
        //Adiciona a torre ao array de torres de menu
        [self.towersFromMenu addObject:sprite];
    }
    
    //Cria o vetor de torres da fase e seta o numero de torres criadas como zero.
    self.towers = [[NSMutableArray alloc] initWithCapacity:TOWERS_SIZE];
    self.towersCreated = 0;
    //FIM - Criação do menu de Torres
}

//Método que seta todos os gridCels ainda não setados como PLACEHOLDERS.
-(void) setPlaceHolders
{
    for(int i = 0; i < LINS; i++)
    {
        for(int j = 0; j < COLS; j++)
        {
            if(matrix[i][j] == nil)
            {
                matrix[i][j] = [[GridClass alloc] initWithI:i withJ:j ofTerrain:PLACEHOLDER withSize:CGSizeMake(self.gridCellWidth, self.gridCellHeight)];
            }
        }
    }

}


//Método de criação de todos os monstros do round.
-(void)createMonsters
{
    //Calcula a quantidade de monstros.
    int boss = self.currentRound == 10 ? 1 : 0;
    int weakMonsters = self.currentRound * 7;
    int averageMonsters = self.currentRound > 0 ? (self.currentRound - 1) * 5 : 0;
    int strongMonsters = self.currentRound > 1 ? (self.currentRound - 2) * 3 : 0;
    
    int monstersAmount = boss + weakMonsters + averageMonsters + strongMonsters;
    
    //Recria Vetor de Monstros
    self.monsters = [[NSMutableArray alloc] initWithCapacity:monstersAmount];
    self.monstersRespawned = 0;
    
    //Posição inicial dos monstros
    GridClass * firstGrid = self.enemyPath[0];
    
    
    //Cria os monstros fracos
    for(int i=0;i<weakMonsters;i++){
        Enemy *enemy = [self createSingleMonsterOfType:LEVEL_00 withPosition:[firstGrid gridCenter]];
        
        //Cria o monstro no Vetor de Monstros
        [self.monsters addObject:enemy];
    }
    
    
    //Cria os monstros médios
    for(int i=0;i<averageMonsters;i++){
        Enemy *enemy = [self createSingleMonsterOfType:LEVEL_01 withPosition:[firstGrid gridCenter]];
        
        //Cria o monstro no Vetor de Monstros
        [self.monsters addObject:enemy];
    }
    
    //Cria os monstros difíceis
    for(int i=0;i<strongMonsters;i++){
        Enemy *enemy = [self createSingleMonsterOfType:LEVEL_02 withPosition:[firstGrid gridCenter]];
        
        //Cria o monstro no Vetor de Monstros
        [self.monsters addObject:enemy];
    }
    
    //Shuffle dos monstros sem contar com o boss
    [self shuffleArray:self.monsters withSize:[self.monsters count]-boss];
    
    //Cria o Boss no final do array
    if(boss)
    {
        Enemy *enemy = [self createSingleMonsterOfType:LEVEL_03 withPosition:[firstGrid gridCenter]];
        
        //Cria o boss no vetor de monstros
        [self.monsters addObject:enemy];
    }
}

//Método auxiliar na criação de monstro.
-(Enemy*)createSingleMonsterOfType:(ENEMY_TYPE)type withPosition:(CGPoint)position
{
    Enemy* enemy = [[Enemy alloc] initWithPosition:position withTypeEnemy:type];
    enemy.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:enemy.size];
    enemy.physicsBody.dynamic = YES;
    enemy.physicsBody.categoryBitMask = monsterCategory;
    enemy.physicsBody.contactTestBitMask = projectileCategory;
    enemy.physicsBody.collisionBitMask = 0;
    
    return enemy;
}

//Método de criação dos reds.
-(void)createReds
{
    //Aloca o novo vetor de reds
    self.reds = [[NSMutableArray alloc] init];
    
    //Posição inicial dos reds
    GridClass * firstGrid = self.redPath[0];
    
    //Cria todos os reds.
    for(int i=0; i<NUMBER_OF_REDS; i++)
    {
        //Cria um novo red.
        Red * red = [[Red alloc] initWithPosition:[firstGrid gridCenter]];
        
        //Fîsica do Red
        red.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:red.size];
        red.physicsBody.dynamic = YES;
        red.physicsBody.categoryBitMask = redCategory;
        red.physicsBody.contactTestBitMask = monsterCategory;
        red.physicsBody.collisionBitMask = 0;
        
        //Coloca o novo Red no vetor de Reds.
        [self.reds addObject:red];
    }
    
}

//Shuffle Array
- (void)shuffleArray: (NSMutableArray*) array withSize:(int)size
{
    for (NSUInteger i = 0; i < size; ++i) {
        NSInteger remainingCount = size - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        [array exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}

//Método de pontos extras na fase extra
-(void)extraPoints: (int)points
{
    self.score+= points;
    self.scoreLabel.text = [NSString stringWithFormat:@"Pontos: %d", self.score];
    self.scoreLabel.position = CGPointMake(self.scoreLabel.frame.size.width/2, [matrix[LINS-2][COLS-1] gridCenter].y);
}



@end