echo "🚀 Frontend watch mode - Ctrl+C to stop" && while inotifywait -q -r app/views public; do ./testall_frontend_content.sh; done
