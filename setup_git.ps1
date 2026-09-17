# A executer depuis le dossier racine du projet
# (C:\Users\ugoal\Documents\EPITA\S9\VHDL\)

# 1. Initialisation du depot
git init

# 2. Creation du .gitignore (fichiers generes par Quartus/Questa, jamais a versionner)
@"
# --- Quartus ---
output_files/
db/
incremental_db/
simulation/
*.qws
*.rpt
*.summary
*.smsg
*.done
*.jdi
*.pin
*.sld
*.qarlog
*.htm
*.qdf
*.sof
*.pof
*.jic
*.map.bin
*.pin.bin
*.fit.bin
*.sta.bin
*.asm.bin
*.pmsf

# --- Questa / ModelSim ---
work/
*.wlf
transcript
vsim.wlf
*.vstf
*.ver
*.vo
*.mti

# --- Backups / fichiers temporaires ---
*.bak
*~
*.tmp
"@ | Set-Content -Encoding UTF8 .gitignore

# 3. Premier commit
git add .
git commit -m "Initial commit : TP4 chronometre/minuteur - structure du projet"

# 4. (Optionnel) Renommer la branche principale en main
git branch -M main

# 5. (Optionnel) Lier a un depot distant existant (GitHub/GitLab), puis pousser
#    Remplace l'URL par celle de ton depot
git remote add origin https://github.com/UgoAlvery/fpga-vga-multifunction-timer.git
git push -u origin main
