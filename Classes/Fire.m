//
//  Fire.m
//  prototype
//
//  Created by Ari Ronen on 11/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Fire.h"
#import "Globals.h"
#import "Terrain.h"
#import "SpecialEffects.h"

@implementation Fire

#define n_particles 17
#define max_fparticles 1000
#define max_bb 500
#define SMOKE_SIZER 140

static unsigned short pindices[max_fparticles];
typedef struct{
	Vector pos;
	int pvbi; //particle vertex buffer index
	float vx,vy,vz;
	float life;
	float slife;   
	
}particle;

typedef struct _bnode{
	particle particles[n_particles];	
	float life;
	int pid;
    BOOL type;
	float x,z,y;
}bnode;

static bnode list[max_bb];
static int list_size;
static int num_particles;
static BOOL updateIndexes;

- (id)init{
	list_size=0;
	updateIndexes=TRUE;
	num_particles=0;
	return self;
	
}
-(void)removeNode:(int)idx{
    
    updateIndexes=TRUE;
    num_particles-=n_particles;   
    
    if(idx!=list_size-1){
        list[idx]=list[list_size-1];
        
    }
    list_size--;
	
    
}

static const float SPEED=.5f;
static const float SPEEDY=2;
extern vertexpStruct pbuffer[pbuffer_size];
- (BOOL)update: (float)etime{
	for(int k=0;k<list_size;k++){
        bnode* node=&list[k];
        
		
		for(int i=0;i<n_particles;i++){
			if(node->particles[i].life<0){
				node->particles[i].pos.x=node->x;
				node->particles[i].pos.y=node->y-.3f;
				node->particles[i].pos.z=node->z;
				
				/*int dps=arc4random()%4;
				
				int dpx[4]={0,1,0,-1};
				int dpz[4]={-1,0,1,0};				
				node->particles[i].pos.x+=dpx[dps]*BLOCK_SIZE/1.7;
				node->particles[i].pos.z+=dpz[dps]*BLOCK_SIZE/1.7;
				int dpai=(arc4random()%200-100);
				float dpa=dpai/100.0f;
				//NSLog(@"a:%f",dpa);
				if(dps%2==0){
					node->particles[i].pos.x+=dpa*BLOCK_SIZE/2;	
					
				}else{					
					node->particles[i].pos.z+=dpa*BLOCK_SIZE/2;	
				
				}*/
				int dx=(arc4random()%200-100);
				int dz=(arc4random()%200-100);
				int dy=(arc4random()%50)+50;
				node->particles[i].vx=dx/100.0f*SPEED;
				node->particles[i].vz=dz/100.0f*SPEED;
				node->particles[i].vy=dy/100.0f*SPEEDY;
				int dlife=(arc4random()%60);
				node->particles[i].life=dlife/60.0f*1+1;
				node->particles[i].slife=node->particles[i].life+1;
                pbuffer[node->particles[i].pvbi].size[0]=SMOKE_SIZER;
			}else{
				//pbuffer[node->particles[i].pvbi].colors[3]=255;
                 if(IS_RETINA||IS_IPAD){
                     if(node->particles[i].life<node->particles[i].slife/2){
                         float alpha;
                         alpha=node->particles[i].life/(node->particles[i].slife/2.0f);
                         pbuffer[node->particles[i].pvbi].colors[3]=alpha*255;
                     }
                     if(node->particles[i].life<node->particles[i].slife/2){
                         /*int size=SMOKE_SIZER*(node->particles[i].slife-node->particles[i].life+1);
                         if(size>SMOKE_SIZER*3){
                             size=SMOKE_SIZER*3;
                         }*/
                         pbuffer[node->particles[i].pvbi].size[0]+=3;
                         
                     }
                     //pbuffer[node->particles[i].pvbi].size[0]=SMOKE_SIZER*node->particles[i].life/node->particles[i].slife;
                 }else{
                     pbuffer[node->particles[i].pvbi].size[0]=75*node->particles[i].life/node->particles[i].slife;
                     
                 }
                //if( pbuffer[node->particles[i].pvbi].colors[1])
                   //  pbuffer[node->particles[i].pvbi].colors[1]=60*(node->particles[i].life/node->particles[i].slife);
				node->particles[i].life-=etime;
				node->particles[i].pos.x+=node->particles[i].vx*etime;
				node->particles[i].pos.y+=node->particles[i].vy*etime;			
				node->particles[i].pos.z+=node->particles[i].vz*etime;
				setParticle(node->particles[i].pos,node->particles[i].pvbi);
			}
		}
		node->life-=etime;
		if(node->life<=0){
			[self removeNode:k];
			
		}
	}
	
	
	if(updateIndexes){
       
		
		num_particles=0;
		 for(int k=0;k<list_size;k++){	
             bnode* node=&list[k];
			for(int i=0;i<n_particles;i++){
				pindices[num_particles++]=node->particles[i].pvbi;
				
			}			
			
		}		

		updateIndexes=FALSE;
	}
	return FALSE;
}
//#define NUM_COLORS 2
const GLubyte colors[2][3]={
	//{255,0,0},
	//{255,100,0},
    
    {255,255,255},
     {255,255,255},
/*	{80,80,80},
	{40,40,40},
	{170,185,40},
	{170,40,40},*/
	
};
-(void)removeFire:(int)ppid{
    
	for(int k=0;k<list_size;k++)
		if(list[k].pid==ppid){
			list[k].life=0;
			break;
		}
    
}
-(void)updateFire:(int)idx:(Vector)pos{
    for(int k=0;k<list_size;k++)
		if(list[k].pid==idx){
			list[k].x=pos.x;
            list[k].y=pos.y;
            list[k].z=pos.z;
			break;
		}
    
}

static int pid=0;
- (int)addFire:(float)x:(float)z:(float)y:(int)type:(float)life{
	
	while(num_particles+n_particles>max_fparticles){
		[self removeNode:arc4random()%list_size];
	}
	num_particles+=n_particles;
	
	bnode* p=&list[list_size];
	
	for(int i=0;i<n_particles;i++){
		p->particles[i].life=-1;		
		
		int pvbi=getPVBI();
		p->particles[i].pvbi=pvbi;
		
		int color=arc4random()%2;
		pbuffer[pvbi].colors[0]=colors[color][0];
		pbuffer[pvbi].colors[1]=colors[color][1];
		pbuffer[pvbi].colors[2]=colors[color][2];
		pbuffer[pvbi].colors[3]=255;
      /*  pbuffer[pvbi].colors[0]=255;
		pbuffer[pvbi].colors[1]=255;
		pbuffer[pvbi].colors[2]=255;*/
        if(IS_RETINA){
             pbuffer[pvbi].size[0]=SMOKE_SIZER;
        }else{
        pbuffer[pvbi].size[0]=70;
        }
	}
	if(type==0){
        p->type=1;
	p->x=x*BLOCK_SIZE+BLOCK_SIZE/2;
	p->y=y*BLOCK_SIZE+BLOCK_SIZE/2;
	p->z=z*BLOCK_SIZE+BLOCK_SIZE/2;
    }else{
        p->type=0;
    }
	p->pid=pid++;
	p->life=life;
	updateIndexes=TRUE;	
	
	list_size++;	
	
	return p->pid;
	
}
Vector getFrameUV(int frame,int sprite){
    Vector uv;
    return uv;
}
static int frame=0,frame2=0;
- (void)renderFireSprites{
   // glDepthMask(GL_TRUE);
    glMatrixMode(GL_TEXTURE);
    glPushMatrix();
    glScalef(1.0f/16,1.0f/8.0f,1);
    
    int framescale=4;
    frame=(frame+1)%((112)*framescale);
    int row=(frame/framescale)/16;
    int col=(frame/framescale)%16;
   // printf("frame: %d\n",frame/framescale);
    glTranslatef(col,row,0);
    glMatrixMode(GL_MODELVIEW);
    
    glDisable(GL_POINT_SPRITE_OES);
    
    glDisableClientState(GL_POINT_SIZE_ARRAY_OES);
	//glDisable(GL_BLEND);
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    vertexObject objVertices[max_bb*6*6];
    extern const GLshort cubeShortVertices[36*3];
    extern const GLshort cubeTexture[36*2];
    const GLshort* cubeTextureCustom=cubeTexture;
    const GLshort* cubeVertices=cubeShortVertices;
    int vert=0;
    float poof=1.11f;
    float epoofx=1.3f;
    float epoofy=1.7f;
    for(int i=0;i<list_size;i++){
        bnode* node=&list[i];
        if(node->life>0)
        for(int k=0;k<6*6;k++){
            Vector vc;
         
            vc=MakeVector((cubeVertices[k*3]-.5f)*poof,(cubeVertices[k*3+1]-.5f)*1.3f*1.2f+.44f,(cubeVertices[k*3+2]-.5f)*poof);
            
            if(k<12){
                vc.x*=epoofx;
                vc.y*=epoofy;
            }else if(k<24){
                vc.y*=epoofy;
                vc.z*=epoofx;
            }else{
                continue;
             //   vc.x*=epoof;
              //  vc.z*=epoof;
            }
            objVertices[vert].position[0]=(node->x)+vc.x;
            objVertices[vert].position[1]=node->y+vc.y;
            objVertices[vert].position[2]=node->z+vc.z;
            
            
            
          
          //  Vector uv=getFrameUV(0,SPRITE_FLAME);
            objVertices[vert].texs[0]=cubeTextureCustom[k*2+0];
            objVertices[vert].texs[1]=cubeTextureCustom[k*2+1];
               
           
            
            
            vert++;
        }
        
       // node->
        
    }
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0);
    glBindBuffer(GL_ARRAY_BUFFER,0);
    
    glBindTexture(GL_TEXTURE_2D, [[Resources getResources] getTex:SPRITE_FLAME].name);
    glVertexPointer(3, GL_FLOAT, sizeof(vertexObject), objVertices[0].position);
   	glTexCoordPointer(2, GL_FLOAT,  sizeof(vertexObject),  objVertices[0].texs);
	
	
    glColor4f(0,0,0,1.0f);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDrawArrays(GL_TRIANGLES, 0,vert);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glColor4f(1.0,1.0,1,1);
    glDrawArrays(GL_TRIANGLES, 0,vert);
    
    
    //////////BOT AND TOP
    glMatrixMode(GL_TEXTURE);
    glPopMatrix();
    glPushMatrix();
    glLoadIdentity();
    glScalef(1.0f/16,1.0f/16.0f,1);
    
    framescale=4;
    frame2=(frame2+1)%((32)*framescale);
    row=(frame2/framescale)/16;
    col=(frame2/framescale)%16;
     //printf("row: %d\n",row);
    glTranslatef(col,row+14,0);
    glMatrixMode(GL_MODELVIEW);
   // glDepthMask(FALSE);
    glColor4f(1.0f,1.0f,1.0f,1.0f);
    poof=1.1;
    float epoof=1.0f;
    vert=0;
    for(int i=0;i<list_size;i++){
        bnode* node=&list[i];
        if(node->life>0)
            for(int k=0;k<6*6;k++){
                Vector vc;
                
                vc=MakeVector((cubeVertices[k*3]-.5f)*poof,(cubeVertices[k*3+1]-.5f)*poof,(cubeVertices[k*3+2]-.5f)*poof);
                
                if(k>=24&&k<30){
                    vc.x*=epoof;
                    vc.z*=epoof;
                
                }else{
                    continue;
                      
                }
                objVertices[vert].position[0]=(node->x)+vc.x;
                objVertices[vert].position[1]=node->y+vc.y;
                objVertices[vert].position[2]=node->z+vc.z;
                
                
                
                
                //  Vector uv=getFrameUV(0,SPRITE_FLAME);
                objVertices[vert].texs[0]=cubeTextureCustom[k*2+0]*.8f+.1f;
                objVertices[vert].texs[1]=cubeTextureCustom[k*2+1]*.8f+.1f;
                
                
                
                
                vert++;
            }
        
        // node->
        
    }
   //  glDepthMask(TRUE);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0);
    glBindBuffer(GL_ARRAY_BUFFER,0);
    
    glBindTexture(GL_TEXTURE_2D, [[Resources getResources] getTex:SPRITE_FLAME].name);
    glVertexPointer(3, GL_FLOAT, sizeof(vertexObject), objVertices[0].position);
   	glTexCoordPointer(2, GL_FLOAT,  sizeof(vertexObject),  objVertices[0].texs);
	
	
    glColor4f(0,0,0,1.0f);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDrawArrays(GL_TRIANGLES, 0,vert);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glColor4f(1.0,1.0,1,1);
    glDrawArrays(GL_TRIANGLES, 0,vert);
    
    
    //////////
    
    glEnableClientState(GL_COLOR_ARRAY);
    
    glMatrixMode(GL_TEXTURE);
    glPopMatrix();
    
    glMatrixMode(GL_MODELVIEW);
    
      /* vertexObject objVertices[max_render_objects*6*6];
    extern const GLshort cubeShortVertices[36*3];
    extern const GLshort cubeTexture[36*2];
    extern const GLfloat cubeNormals[36*3];
    const GLshort* cubeVertices=cubeShortVertices;
    const GLshort* cubeTextureCustom=cubeTexture;
    int vert=0;
    int object=0;
    
    Vector ppos=[World getWorld].player.pos;
    for(int i=0;i<chunksr;i++){
        for(int j=0;j<renderList[i].rtnum_objects;j++){
            if(renderList[i].rtobjects[j].type!=TYPE_DOOR_TOP)continue;
            int dir=renderList[i].rtobjects[j].dir;
            Vector v1=renderList[i].rtobjects[j].pos;
            v1.x+=.5f;
            v1.z+=.5f;
            v1.y=ppos.y;
            Vector vdist=v_sub(ppos,v1);
            
            int dist=v_length2(vdist);
            
            if(ppos.y>=renderList[i].rtobjects[j].pos.y&&ppos.y<=renderList[i].rtobjects[j].pos.y+2&&dist<2*2){
                renderList[i].rtobjects[j].ani=-1;
            }else
                renderList[i].rtobjects[j].ani=1;
            float rot=renderList[i].rtobjects[j].rot;
           
            if(renderList[i].rtobjects[j].ani==1){
                renderList[i].rtobjects[j].rot+=6*last_etime;
            }else if(renderList[i].rtobjects[j].ani==-1){
                renderList[i].rtobjects[j].rot-=6*last_etime;
            }
            if(renderList[i].rtobjects[j].rot<0){
                renderList[i].rtobjects[j].rot=0;
                // renderList[i].rtobjects[j].ani=1;
            }
            if(renderList[i].rtobjects[j].rot>M_PI/2){
                renderList[i].rtobjects[j].rot=M_PI/2;
                //renderList[i].rtobjects[j].ani=-1;
            }
            Vector offsets=MakeVector(0,0,0);
            if(dir==0){
                offsets.x=4;
                rot+=M_PI/2;
            }else if(dir==1){
                rot+=M_PI;
                offsets.z=4;
                offsets.x=4;
                
                
            }else if(dir==2){
                rot+=M_PI+M_PI/2;
                offsets.z=4;
                
            }else if(dir==3){
                
            }
            
            if(rot>2*M_PI)rot-=(int)(rot/(2*M_PI))*(2*M_PI);
            
            
            for(int k=0;k<6*6;k++){
                Vector vc;
                
                vc=MakeVector(cubeVertices[k*3]*4,cubeVertices[k*3+1]*2*4,cubeVertices[k*3+2]*.50f-.25);
                
                
                
                vc=rotateVertice(MakeVector(0,rot,0),vc);
                vc.x+=offsets.x;
                vc.z+=offsets.z;
                if(vc.x<0)vc.x=0;
                if(vc.z<0)vc.z=0;
                if(vc.x>4)vc.x=4;
                if(vc.z>4)vc.z=4;
               
                objVertices[vert].position[0]=4*(renderList[i].rtobjects[j].pos.x-[World getWorld].fm.chunkOffsetX*CHUNK_SIZE)+vc.x;
                objVertices[vert].position[1]=4*renderList[i].rtobjects[j].pos.y+vc.y;
                objVertices[vert].position[2]=4*(renderList[i].rtobjects[j].pos.z-[World getWorld].fm.chunkOffsetZ*CHUNK_SIZE)+vc.z;
               
                    
              
                Vector vn=MakeVector(cubeNormals[k*3],cubeNormals[k*3+1],cubeNormals[k*3+2]);
                
                vn=rotateVertice(MakeVector(0,rot,0),vn);
                objVertices[vert].normal[0]=vn.x;
                objVertices[vert].normal[1]=vn.y;
                objVertices[vert].normal[2]=vn.z;
                               if(k>=12){
                    objVertices[vert].texs[0]=cubeTextureCustom[k*2+0];
                    objVertices[vert].texs[1]=0;
                }else{
                    if(k>=6){
                        objVertices[vert].texs[0]=cubeTextureCustom[k*2+0];
                        objVertices[vert].texs[1]=cubeTextureCustom[k*2+1]*32;
                    }
                    else{
                        objVertices[vert].texs[0]=1-cubeTextureCustom[k*2+0];
                        objVertices[vert].texs[1]=cubeTextureCustom[k*2+1]*32;
                        
                        
                    }
                }
                extern Vector colorTable[256];
                Vector color=colorTable[renderList[i].rtobjects[j].color];
                if(renderList[i].rtobjects[j].color==0){
                    color.x=color.y=color.z=1;
                    
                }
                objVertices[vert].colors[0]=color.x*255;
                objVertices[vert].colors[1]=color.y*255;
                objVertices[vert].colors[2]=color.z*255;
                objVertices[vert].colors[3]=255;
                vert++;
            }
            object++;
            if(object==max_render_objects)break;
        }
        if(object==max_render_objects)break;
    }
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0);
    glBindBuffer(GL_ARRAY_BUFFER,0);
    
    glBindTexture(GL_TEXTURE_2D, [[Resources getResources] getTex:ICO_DOOR].name);
    glVertexPointer(3, GL_FLOAT, sizeof(vertexObject), objVertices[0].position);
    glNormalPointer( GL_FLOAT, sizeof(vertexObject), objVertices[0].normal);
	glTexCoordPointer(2, GL_FLOAT,  sizeof(vertexObject),  objVertices[0].texs);
	glColorPointer(	4, GL_UNSIGNED_BYTE, sizeof(vertexObject), objVertices[0].colors);
	
    
    glDrawArrays(GL_TRIANGLES, 0,vert);*/

    
    
}
- (void)render{
   /* glColor4f(0,0,0,1.0f);
    glDisableClientState(GL_COLOR_ARRAY);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glDrawElements(GL_POINTS,num_particles,GL_UNSIGNED_SHORT,pindices);	
   */ glEnableClientState(GL_COLOR_ARRAY);
     glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glColor4f(1,1,1,1.0f);
	glDrawElements(GL_POINTS,num_particles,GL_UNSIGNED_SHORT,pindices);
    
   // glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [self renderFireSprites];
    
}
- (void)clearAllEffects{
	updateIndexes=TRUE;
    list_size=0;
    num_particles=0;
	
	
}
@end
