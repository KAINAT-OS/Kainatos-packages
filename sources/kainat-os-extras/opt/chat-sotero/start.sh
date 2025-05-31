#!/usr/bin/env bash
set -e
cd /opt/chat-sotero/

# Get the real (logged-in) user and home
ENV_PATH="$HOME/.config/chat-sotero/.env"


echo $ENV_PATH



# 1) Ensure .env exists
if [ ! -f $ENV_PATH ]; then
    /usr/bin/kdialog --error "Please set both HUGGINGFACE_EMAIL and HUGGINGFACE_PASSWORD in the chatbot-setup app."
    hugging-chat-login.x86_64
fi

# 2) Create & activate virtual environment
if [ ! -d venv ]; then
  python3 -m venv venv
  echo "Virtual environment created at ./venv"
fi
source venv/bin/activate

# 3) Create requirements.txt if missing
if [ ! -f requirements.txt ]; then
  cat > requirements.txt <<EOF
hugchat
gradio
python-dotenv
huggingface-hub
EOF
  echo "requirements.txt created."
fi

# 4) Install/upgrade dependencies
pip install --upgrade pip
pip install -r requirements.txt

# 5) Create app.py stub if missing (with input-clearing on send)
if [ ! -f app.py ]; then
  cat > app.py <<'EOF'
import os
from dotenv import load_dotenv
import gradio as gr
from hugchat import hugchat
from hugchat.login import Login

# Load credentials
env_path = os.getenv("ENV_PATH", os.path.expanduser("~/.config/chat-sotero/.env"))
load_dotenv(dotenv_path=env_path)
EMAIL = os.getenv("HUGGINGFACE_EMAIL")
PASSWD = os.getenv("HUGGINGFACE_PASSWORD")
if not EMAIL or not PASSWD:
    exit

# Login & init ChatBot
cookie_dir = './cookies/'
login = Login(EMAIL, PASSWD)
cookies = login.login(cookie_dir_path=cookie_dir, save_cookies=True)
chatbot = hugchat.ChatBot(cookies=cookies.get_dict())

# Select assistant & model
ASSISTANT_ID = "6839ccd445f82e0393fcc101"
chatbot.new_conversation(assistant=ASSISTANT_ID, switch_to=True)
chatbot.switch_llm(7)  # Qwen/QwQ-32B

# In-memory history as list of dicts
chat_history = []

def respond(message, web_search):
    global chat_history

    # record user message
    chat_history.append({"role": "user", "content": message})

    # Web-search branch (no streaming)
    if web_search:
        raw = chatbot.chat(message, web_search=True).wait_until_done()
        reply = getattr(raw, "msg", raw)
        chat_history.append({"role": "assistant", "content": reply})
        if hasattr(raw, "get_search_sources"):
            sources = [f"[{s.title}]({s.link})" for s in raw.get_search_sources()]
        else:
           sources = ["(no sources available)"]
        # clear input by returning "" for inp
        yield chat_history, "\n".join(sources), ""
        return

    # Streaming branch
    for chunk in chatbot.chat(message, stream=True):
        if hasattr(chunk, "msg"):
            text = chunk.msg
        elif isinstance(chunk, dict):
            text = chunk.get("token") or chunk.get("msg") or ""
        else:
            text = str(chunk)

        if not chat_history or chat_history[-1]["role"] != "assistant":
            chat_history.append({"role": "assistant", "content": text})
        else:
            chat_history[-1]["content"] += text

        # on each stream chunk, clear inp to keep it empty
        yield chat_history, "", ""

    # final yield to close out
    yield chat_history, "", ""

# Dark Gradio UI
css = '''
.gradio-container { background-color: #1e1e1e; color: #f0f0f0; }
.gradio-chatbot { background-color: #2e2e2e; }
.gradio-textbox { background-color: #2e2e2e; color: #f0f0f0; }
'''

with gr.Blocks(css=css) as demo:
    gr.Markdown("# 🧠 chat Sotero")
    chat_ui = gr.Chatbot(type="messages")
    with gr.Row():
        inp  = gr.Textbox(placeholder="Your message...", show_label=False, scale=4)
        web  = gr.Checkbox(label="Web Search", scale=1)
        send = gr.Button("Send", scale=1)
    out = gr.Textbox(label="Search Results", interactive=False)

    # Now outputs include inp itself to clear it
    send.click(fn=respond,
               inputs=[inp, web],
               outputs=[chat_ui, out, inp])
    demo.queue()

if __name__ == "__main__":
    demo.launch()
EOF
  echo "app.py created."
fi


export ENV_PATH="$ENV_PATH"
python app.py

# 6) Launch the app
python app.py
