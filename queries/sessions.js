export const query = `
query {
  sessions {
    id
    expiresAt
    mails {
      rawSize
      fromAddr
      toAddr
      downloadUrl
      text
      headerSubject
      attachments {
        downloadUrl
        id
        name
      }
    }
  }
}
`;
