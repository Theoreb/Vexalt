
# Vexalt

Test for a 3D Graphic Engine in Julia


## Run Locally

#### Step 1

[Install Julia](https://julialang.org/downloads/)

#### Step 2

Clone the project

```bash
  git clone https://github.com/Theoreb/Vexalt
  cd Vexalt
```

#### Step 3

Install dependencies

```julia
  julia> using Pkg
  julia> Pkg.add(["Quaternions","LinearAlgebra","StaticArrays","ModernGL","CSyntax","GLFW"])
```

#### Step 4

Start the game

```bash
  bash run.bat
```


## In Progress

1/ Créer un système de création / déconstruction de chunk dynamique ( ~1 Go de Ram)
	
    - Utilisation d'une liste d'attente de taille fixe
	- Un index uniform attribué pour chaque element fixe de la liste d'attente
	- Utilisation propice aux threads
        - voxel avec index en [Morton code](https://github.com/JaneliaSciComp/Morton.jl)

2/ Optimiser la taille des vertex
	
    - 8 bits pour le type (couleur encodé in-shader) [0;255]
	- 5 bits * 3 pour les coordonnées [0;31]
	- AUCUN bits pour l'index uniforme
             - Utilisation d'un vbo statique ou par glElementID
	- Uniform de 32 bits
	- Normal de la face directement dans le vbo statique des vertices

3/ Optimisation du vertex polling (caméra)
	
    - Frustrum chunks culling
	- Faces culling
	- Proximity Sorting (Tri en profondeur)

4/ Mise en cache
	
    - Octotrees et compteur de voxel
    - Morton.jl

5/ Optimisation des détails - LOD (Level of detail)
	
    - Utilisation d'une variance du vbo des vertices
	- Voxel de taille 2*2 ou 4*4 selon leurs distances

6/ Variance de couleur in-shader
	
    - Plague [-3;3] avec utilisation de glFragment position
	- Fonction sin modifiée

7/ Changement dynamique dans les buckets en multi-threading
	
    - 1 index de buckets fixes pour chaque element chunk
	- Stockage d'une liste d'index de voxels vers un pointeur	[DataPointer, IndexPointer] (default = [DataPointer, currentPointer] )
	- UShort / UInt

8/ RefValue pour le paramètre index des DEIC

    - Changement de l'index dynamique sans nouvelle allocation

10 / [Lighting](https://web.archive.org/web/20200319071420/http://codeflow.org/entries/2010/dec/09/minecraft-like-rendering-experiments-in-opengl-4/)




## Screenshots

![App Screenshot](https://camo.githubusercontent.com/0a44d14a9c93b7f6f3de6ca3d060e0ddef93e18a4fa80ac61a6927f2fcf57c7e/68747470733a2f2f63646e2e646973636f72646170702e636f6d2f6174746163686d656e74732f3738323637303434343438353933353135352f3939343635383935303238363933383133322f756e6b6e6f776e2e706e67)

