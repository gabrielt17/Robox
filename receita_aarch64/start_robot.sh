#!/bin/bash

# ==============================================
# 🤖 Controle do Robô via ROS Noetic
# ==============================================

# --- Função para encerramento limpo ---
cleanup() {
    echo
    echo "🧹 Encerrando processos ROS..."
    kill $ROSCORE_PID $ROSSERIAL_PID $PUB_PID 2>/dev/null
    sleep 1
    echo "✅ Todos os processos encerrados."
    exit 0
}
trap cleanup SIGINT

# --- Verifica se o ROS está disponível ---
if ! command -v roscore >/dev/null 2>&1; then
    echo "❌ ROS não encontrado! Execute este script dentro do container ROS Noetic."
    exit 1
fi

# --- Detecta o IP local ---
IP=$(hostname -I | awk '{print $2}')
if [ -z "$IP" ]; then
    echo "⚠️  Não foi possível detectar o IP automaticamente. Usando 127.0.0.1"
    IP="127.0.0.1"
fi

export ROS_IP=$IP
export ROS_MASTER_URI="http://$ROS_IP:11311"

echo "=============================================="
echo "     🤖 Controle do Robô via ROS Noetic        "
echo "=============================================="
echo
echo "🌐 Endereço IP detectado: $ROS_IP"
echo "🔧 ROS_MASTER_URI definido como: $ROS_MASTER_URI"
echo

# --- Dá source na workspace para carregar as msgs move/Move ---
if [ -f ./devel/setup.bash ]; then
    source ./devel/setup.bash
    echo "✅ Workspace carregada (devel/setup.bash)"
else
    echo "⚠️  Atenção: ./devel/setup.bash não encontrado!"
    echo "   Verifique se você está na raiz da sua workspace."
    exit 1
fi

# --- Mata processos antigos ---
echo "🧹 Encerrando possíveis processos anteriores..."
pkill -f roscore >/dev/null 2>&1
pkill -f rosrun >/dev/null 2>&1
sleep 1

# --- Inicia o roscore ---
echo "🚀 Iniciando roscore..."
roscore >/tmp/roscore.log 2>&1 &
ROSCORE_PID=$!

# --- Aguarda o roscore subir ---
for i in {1..10}; do
    if rostopic list >/dev/null 2>&1; then
        echo "✅ roscore está ativo."
        break
    else
        echo "⏳ Aguardando roscore iniciar..."
        sleep 1
    fi
done

# --- Inicia o rosserial TCP ---
echo "🔌 Tentando iniciar rosserial (rosrun rosserial_python serial_node.py tcp)..."
rosrun rosserial_python serial_node.py tcp >/tmp/rosserial.log 2>&1 &
ROSSERIAL_PID=$!
sleep 2
if ps -p $ROSSERIAL_PID >/dev/null 2>&1; then
    echo "✅ rosserial rodando."
else
    echo "⚠️  rosserial não pôde ser iniciado (verifique hardware/conexão)."
fi

echo
echo "=============================================="
echo "Controle de Movimento (/Move)"
echo "----------------------------------------------"
echo "Direções:"
echo "  f → frente"
echo "  b → trás (backward)"
echo "  e → esquerda"
echo "  d → direita"
echo
echo "Potência (power): 0 a 100"
echo "Pressione 'z' durante o movimento para parar"
echo "Pressione 'q' para sair do programa"
echo "=============================================="
echo

# --- Loop principal de controle ---
while true; do
    read -p "👉 Digite a direção (f/b/e/d) ou 'q' para sair: " direction
    if [[ "$direction" == "q" ]]; then
        echo "👋 Encerrando o programa..."
        cleanup
    fi

    case $direction in
        f|b|e|d) ;;
        *) echo "❌ Direção inválida!"; continue ;;
    esac

    read -p "⚡ Digite a potência (0–100): " power
    if ! [[ "$power" =~ ^[0-9]+$ ]] || [ "$power" -lt 0 ] || [ "$power" -gt 100 ]; then
        echo "❌ Potência inválida! Deve estar entre 0 e 100."
        continue
    fi

    echo
    echo "📡 Enviando comando: direção=$direction, potência=$power ..."
    echo "➡️  Pressione 'z' para parar o robô."

    # Executa o rostopic pub em background
    rostopic pub -r 10 /Move move/Move "{direction: '$direction', power: $power}" &
    PUB_PID=$!

    # Espera tecla 'z' para parar
    while true; do
        read -n1 -s key
        if [[ "$key" == "z" ]]; then
            echo
            echo "🛑 Parando o robô..."
            kill $PUB_PID >/dev/null 2>&1
            break
        fi
    done
    echo
done
