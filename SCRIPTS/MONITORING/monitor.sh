#!/bin/bash
# Manage Lock Monitor Daemon

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITOR_SCRIPT="$SCRIPT_DIR/lock_monitor.sh"
PID_FILE="$SCRIPT_DIR/locks/lock_monitor.pid"
LOG_FILE="$SCRIPT_DIR/logs/lock_monitor.log"

case "$1" in
    start)
        if [ -f "$PID_FILE" ]; then
            pid=$(cat "$PID_FILE")
            if kill -0 "$pid" 2>/dev/null; then
                echo "Lock monitor already running (PID: $pid)"
                exit 0
            else
                rm -f "$PID_FILE"
            fi
        fi
        
        echo "Starting lock monitor..."
        nohup bash "$MONITOR_SCRIPT" > /dev/null 2>&1 &
        sleep 1
        
        if [ -f "$PID_FILE" ]; then
            pid=$(cat "$PID_FILE")
            echo "Lock monitor started (PID: $pid)"
            echo "View logs: tail -f $LOG_FILE"
        else
            echo "Failed to start lock monitor"
            exit 1
        fi
        ;;
        
    stop)
        if [ ! -f "$PID_FILE" ]; then
            echo "Lock monitor is not running"
            exit 0
        fi
        
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Stopping lock monitor (PID: $pid)..."
            kill "$pid"
            sleep 1
            
            if kill -0 "$pid" 2>/dev/null; then
                echo "Force stopping..."
                kill -9 "$pid" 2>/dev/null
            fi
            
            rm -f "$PID_FILE"
            echo "Lock monitor stopped"
        else
            echo "Lock monitor not running (stale PID file)"
            rm -f "$PID_FILE"
        fi
        ;;
        
    restart)
        $0 stop
        sleep 1
        $0 start
        ;;
        
    status)
        if [ ! -f "$PID_FILE" ]; then
            echo "Lock monitor: NOT RUNNING"
            exit 1
        fi
        
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Lock monitor: RUNNING (PID: $pid)"
            
            # Show recent activity
            if [ -f "$LOG_FILE" ]; then
                echo ""
                echo "Recent activity (last 10 lines):"
                tail -10 "$LOG_FILE" | sed 's/^/  /'
            fi
            exit 0
        else
            echo "Lock monitor: NOT RUNNING (stale PID: $pid)"
            rm -f "$PID_FILE"
            exit 1
        fi
        ;;
        
    logs)
        if [ ! -f "$LOG_FILE" ]; then
            echo "No log file found at $LOG_FILE"
            exit 1
        fi
        
        if [ "$2" = "-f" ] || [ "$2" = "--follow" ]; then
            tail -f "$LOG_FILE"
        else
            tail -50 "$LOG_FILE"
        fi
        ;;
        
    *)
        echo "Lock Monitor Manager"
        echo ""
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start    - Start the lock monitor daemon"
        echo "  stop     - Stop the lock monitor daemon"
        echo "  restart  - Restart the lock monitor daemon"
        echo "  status   - Check if monitor is running and show recent activity"
        echo "  logs     - Show recent log entries (add -f to follow)"
        echo ""
        echo "Examples:"
        echo "  $0 start"
        echo "  $0 status"
        echo "  $0 logs -f"
        exit 1
        ;;
esac
