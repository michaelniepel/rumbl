import Player from "./player"

let Video = {
  init(socket, element) {
    if (!element) return
    let playerId = element.getAttribute("data-player-id")
    let videoId = element.getAttribute("data-id")
    socket.connect()
    Player.init(element.id, playerId, () => {
      this.onReady(videoId, socket)
    })
  },
  onReady(videoId, socket) {
    let msgContainer = document.getElementById("msg-container")
    let msgInput = document.getElementById("msg-input")
    let postButton = document.getElementById("msg-submit")
    let videoChannel = socket.channel("videos:"+videoId)

    videoChannel.on("ping", ({count}) => console.debug("PING", count))

    postButton.addEventListener("click", e => {
      let payload = {body: msgInput.value, at: Player.getCurrentTime()}
      videoChannel.push("new_annotation", payload)
        .receive("error", e => {
          console.error("error pushing new_annotation", e)
        })
        msgInput.value = ""
    })

    videoChannel.on("new_annotation", (resp) => {
      videoChannel.params.last_seen_order = resp.order
      this.renderAnnotation(msgContainer, resp)
    })

    msgContainer.addEventListener("click", e => {
      e.preventDefault()
      let seconds = e.target.getAttribute("data-seek") || e.target.parentNode.getAttribute("data-seek")
      if (!seconds) return
      Player.seekTo(seconds)
    })

    videoChannel.join()
      .receive("ok", ({annotations}) => {
        let orders = annotations.map(ann => ann.order)
        if (orders.length > 0) {
          videoChannel.params.last_seen_order = Math.max(...orders)
        }
        this.scheduleMessages(msgContainer, annotations)
        // annotations.forEach(ann => this.renderAnnotation(msgContainer, ann))
      })
      .receive("error", reason => {
        console.error("join failed", reason)
      })
  },
  scheduleMessages(msgContainer, annotations) {
    setTimeout(() => {
      let ctime = Player.getCurrentTime()
      let remaining = this.renderAtTime(annotations, ctime, msgContainer)
      this.scheduleMessages(msgContainer, remaining)
    }, 1000)
  },
  esc(str) {
    let div = document.createElement("div")
    div.appendChild(document.createTextNode(str))
    return div.innerHTML
  },
  renderAnnotation(msgContainer, {user, body, at}) {
    let template = document.createElement("div")
    template.innerHTML = `
      <a href="#" data-seek="${this.esc(at)}">
        [${this.formatTime(at)}]
        <b>${this.esc(user.username)}</b>: ${this.esc(body)}
      </a>
    `
    msgContainer.appendChild(template)
    msgContainer.scrollTop = msgContainer.scrollHeight
  },
  renderAtTime(annotations, seconds, msgContainer) {
    return annotations.filter( ann => {
      if (ann.at > seconds) {
        return true
      } else {
        this.renderAnnotation(msgContainer, ann)
        return false
      }
    })
  },
  formatTime(at) {
    let date = new Date(null)
    date.setSeconds(at / 1000)
    return date.toISOString().substr(14, 5)
  }
}


export default Video
