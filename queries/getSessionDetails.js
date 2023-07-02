export function getSessionDetails(sessionId) {
  return `query getSessionDetails{
    session(id: "${sessionId}") {
      addresses {
        address
      }
      mails {
        rawSize
        fromAddr
        toAddr
        downloadUrl
        text
        html
        receivedAt
        headerSubject
        attachments {
          downloadUrl
          id
          name
        }
      }
    }
  }`;
}

