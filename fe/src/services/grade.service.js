import http from "../http-common";

class GradeDataService {
  getAll() {
    return http.get("/grades");
  }

  get(id) {
    return http.get(`/grades/${id}`);
  }

  create(data) {
    return http.post("/grades", data);
  }

  update(id, data) {
    return http.put(`/grades/${id}`, data);
  }

  delete(id) {
    return http.delete(`/grades/${id}`);
  }

  deleteAll() {
    return http.delete(`/grades`);
  }

  findByTitle(title) {
    return http.get(`/grades?title=${title}`);
  }
}

export default new GradeDataService();