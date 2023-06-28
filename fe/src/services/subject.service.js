import http from "../http-common";

class SubjectDataService {
  getAll() {
    return http.get("/subjects");
  }

  get(id) {
    return http.get(`/subjects/${id}`);
  }

  create(data) {
    return http.post("/subjects", data);
  }

  update(id, data) {
    return http.put(`/subjects/${id}`, data);
  }

  delete(id) {
    return http.delete(`/subjects/${id}`);
  }

  deleteAll() {
    return http.delete(`/subjects`);
  }

  findByTitle(title) {
    return http.get(`/subjects?title=${title}`);
  }
}

export default new SubjectDataService();