import {Socket} from "phoenix"

let socket = new Socket("/socket", {
  params: {token: window.userToken},
  logger: (kind, msg, data) => {
    console.debug(`${kind}: ${msg}`, data)
  }
})

export default socket
