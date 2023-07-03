<template>
  <div>
    <div v-if="loading" class="loading-overlay">
      <v-progress-circular indeterminate size="64"></v-progress-circular>
    </div>
    <v-row justify="center" align="center">
      <v-col cols="12" sm="8" md="6">
        <v-card class="py-4">
          <v-form>
            <v-container fluid>
              <v-row>
                <v-col cols="12">
                  <p>Your temporary email address</p>
                  <v-card
                    outlined
                    class="d-flex align-center justify-center pa-2"
                  >
                    <p class="display-1 mb-0">{{ email }}</p>
                    <v-btn icon @click="copyValue">
                      <v-icon>mdi-content-copy</v-icon>
                    </v-btn>
                  </v-card>
                </v-col>
              </v-row>
              <v-row class="justify-center">
                <v-col cols="12" align="center">
                  <v-icon>{{ countdownIcon }}</v-icon> <p>Updating in: {{ countdown }} seconds</p>
                </v-col>
              </v-row>
              <v-row>
                <v-col cols="12" sm="4" md="2" align="center">
                  <v-btn color="primary" @click="forceUpdate">Update Now</v-btn>
                </v-col>
                <v-col cols="12" sm="4" md="5" align="center">
                  <v-btn color="primary" @click="generateNewEmail"
                    >Generate New E-mail Address</v-btn
                  >
                </v-col>
                <v-col cols="12" sm="4" md="5" align="center">
                  <v-btn
                    color="primary"
                    @click="requestNotificationPermission"
                    v-if="!notificationPermissionGranted"
                    >Receive notifications</v-btn
                  >
                  <v-btn color="primary" disabled v-else
                    >Notifications already enabled</v-btn
                  >
                </v-col>
              </v-row>
            </v-container>
          </v-form>
        </v-card>

        <v-snackbar v-model="showSnackbar" :timeout="3000" top>
          E-mail copied to clipboard.
        </v-snackbar>
      </v-col>
    </v-row>

    <v-container fluid>
      <v-row>
        <v-col cols="12" sm="4">
          <v-card>
            <v-list three-line>
              <v-subheader v-text="'Inbox'"></v-subheader>
              <template v-for="(item, index) in sessionDetails.mails">
                <v-list-item
                  :key="index"
                  :class="{ selected: selected === index }"
                  @mouseover="hovering = index"
                  @mouseleave="hovering = -1"
                  @click="selected = index"
                >
                  <v-list-item-content>
                    <v-list-item-title
                      v-html="item.fromAddr"
                    ></v-list-item-title>
                    <v-list-item-subtitle
                      v-html="item.headerSubject"
                    ></v-list-item-subtitle>
                  </v-list-item-content>
                </v-list-item>
                <v-divider
                  v-if="index < sessionDetails.mails.length - 1"
                  :key="item.text"
                ></v-divider>
              </template>
            </v-list>
          </v-card>
        </v-col>
        <v-col cols="12" sm="8" class="mt-sm-4">
          <v-card v-if="selected !== -1">
            <v-card-title>
              <span class="headline">Message</span>
            </v-card-title>
            <v-card-text>
              <v-container>
                <v-row>
                  <v-col cols="12">
                    <b>From: </b>{{ sessionDetails.mails[selected].fromAddr }}
                    <v-divider></v-divider>
                    <b>To: </b>{{ sessionDetails.mails[selected].toAddr }}
                    <v-divider></v-divider>
                    <b>Date: </b> {{  formatDate(sessionDetails.mails[selected].receivedAt) }}
                    <v-divider></v-divider>
                    <b>Subject: </b
                    >{{ sessionDetails.mails[selected].headerSubject }}
                    <v-divider></v-divider>
                    <b>Message: </b> <p v-html="sessionDetails.mails[selected].html"></p>
                    <v-divider></v-divider>
                    <b v-if="sessionDetails.mails[selected].attachments > 0"
                      >Attachments:
                    </b>
                    <span
                      v-for="(item, index) in sessionDetails.mails[selected]
                        .attachments"
                      :key="index"
                    >
                      <a :href="item.downloadUrl" target="_blank">{{
                        item.name
                      }}</a>
                      &nbsp;
                    </span>
                  </v-col>
                </v-row>
              </v-container>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script>
import { getSessionDetails } from "@/queries/getSessionDetails.js";
import { introduceSession } from "@/queries/introduceSession.js";

export default {
  data() {
    return {
      session: [],
      sessionDetails: [],
      email: null,
      showSnackbar: false,
      hovering: -1,
      selected: -1,
      countdown: 15,
      countdownIcon: "mdi-timer-outline",
      darkMode: false,
      notificationPermissionGranted: false,
      loading: true,
    };
  },

  async mounted() {
    try {
      if (await this.checkSessionIsValid()) {
        await this.getSessionDetails(localStorage.getItem("sessionId"));
      } else {
        await this.introduceSession();
        await this.getSessionDetails(localStorage.getItem("sessionId"));
      }
    } catch (error) {
      console.log(error);
      this.loading = false;
    }

    this.email = localStorage.getItem("email");

    this.notificationPermissionGranted = Notification.permission === "granted";

    setInterval(() => {
      this.countdown--;
      if (this.countdown === 0) {
        this.getSessionDetails(localStorage.getItem("sessionId"));
        this.countdown = 15;
        this.countdownIcon = "mdi-timer-outline";
      } else if (this.countdown <= 5) {
        this.countdownIcon = "mdi-timer-alert-outline";
      }
    }, 1000);
  },

  methods: {
    async introduceSession() {
      this.loading = true;
      const response = await this.$axios.$post("/graphql", {
        query: introduceSession,
      });

      this.session = response.data.introduceSession;

      localStorage.setItem("sessionId", this.session.id);
      localStorage.setItem("email", this.session.addresses[0].address);
      this.loading = false;
    },

    async getSessionDetails(id) {
      this.loading = true;
      const response = await this.$axios.$post("/graphql", {
        query: getSessionDetails(id),
      });

      this.sessionDetails = response.data.session;
      localStorage.setItem("email", this.sessionDetails.addresses[0].address);
      this.loading = false;
    },

    async checkSessionIsValid() {
      this.loading = true;
      const response = await this.$axios.$post("/graphql", {
        query: getSessionDetails(localStorage.getItem("sessionId")),
      });

      this.loading = false;
      return response.data.session === null ? false : true;
    },

    async copyValue() {
      const inputElement = document.createElement("input");
      inputElement.value = this.email;
      document.body.appendChild(inputElement);
      inputElement.select();
      document.execCommand("copy");
      document.body.removeChild(inputElement);

      this.showSnackbar = true;

      setTimeout(() => {
        this.showSnackbar = false;
      }, 3000);
    },

    async forceUpdate() {
      this.loading = true;
      await this.getSessionDetails(localStorage.getItem("sessionId"));
      this.countdown = 15;
      this.countdownIcon = "mdi-timer-outline";
      this.loading = false;
    },

    async generateNewEmail() {
      this.loading = true;
      await this.introduceSession();
      await this.getSessionDetails(localStorage.getItem("sessionId"));
      this.countdown = 15;
      this.countdownIcon = "mdi-timer-outline";
      this.loading = false;
    },

    async requestNotificationPermission() {
      if (!("Notification" in window)) {
        alert("Your browser does not support notifications");
        return;
      }

      let permission = Notification.permission;

      if (permission === "default") {
        permission = await Notification.requestPermission();
        if (permission === "granted") {
          this.notificationPermissionGranted = true;
        }
      }
    },

    async showNotification(email) {
      if (
        !("Notification" in window) ||
        Notification.permission !== "granted"
      ) {
        return;
      }

      const notification = new Notification("Novo email recebido", {
        body: `You have received a new email from ${email}`,
      });
    },


    formatDate(date) {
      const dateObject = new Date(date);
      const day = dateObject.getDate();
      const month = dateObject.getMonth() + 1;
      const year = dateObject.getFullYear();
      const hour = dateObject.getHours();
      const minutes = dateObject.getMinutes();
      const seconds = dateObject.getSeconds();

      return `${day}/${month}/${year} ${hour}:${minutes}:${seconds}`;
    },
  },

  watch: {
    darkMode(newVal) {
      if (newVal) {
        document.documentElement.classList.add("dark-mode");
      } else {
        document.documentElement.classList.remove("dark-mode");
      }
    },

    "sessionDetails.mails"(newMails, oldMails) {
      if (oldMails && newMails.length > oldMails.length) {
        this.showNotification(this.email);
      }
    },
  },
};
</script>

<style scoped>
.selected {
  background-color: #9e9e9e;
  cursor: pointer;
}
.dark-mode .selected {
  background-color: #9e9e9e;
}

.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(255, 255, 255, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}
</style>
